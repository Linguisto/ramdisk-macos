# ramdisk for macOS

Create a temporary RAM disk on your Mac with one command. Use it for scratch
files, temporary workspaces, or tools that need a regular file on a mounted
volume. When you are finished, unmount it to discard its contents.

The package also includes **ramstage**: decompress an image directly into a
RAM disk, without keeping an extracted copy on your SSD. It produces a normal,
seekable file that you can pass to a flashing tool such as `rkdeveloptool`.

Requires **macOS 13 Ventura or later**. Available through Homebrew for Apple
Silicon and Intel Macs; the commands are Bash scripts using macOS disk tools.

## Install with Homebrew

```sh
brew tap linguisto/util
brew trust linguisto/util
brew install linguisto/util/ramdisk
```

The trust step grants Homebrew permission to use the formulae in this tap.
Homebrew installs the `xz` and `zstd` dependencies and makes three commands
available: `ramdisk`, `ramstage`, and `ramunstage`. Bash, gzip, bzip2, and
`diskutil` come with macOS. No compiler, manual PATH changes, or sudo are needed
for the Homebrew installation.

## Create and use a RAM disk

Create a 4 GiB volume and open it in Finder:

```sh
ramdisk mount 4g
open /Volumes/RAMDisk
```

Use `/Volumes/RAMDisk` like any other volume: copy files into it, save temporary
output there, or pass paths inside it to other programs. The disk stays mounted
after the command exits.

When finished, close files and programs using the volume, then remove it:

```sh
ramdisk umount
```

This discards **all files on that RAM disk**. Its contents also disappear on
reboot. Keep anything you need on persistent storage before unmounting.

Sizes are positive integers followed by `m` or `g`, meaning binary MiB or GiB.
For example, `ramdisk mount 512m` creates a 512 MiB disk. Uppercase `M` and `G`
work too. Leave RAM for macOS and your applications; the requested disk must be
smaller than physical RAM.

## Decompress an image into RAM

Use `ramstage` when you have a compressed disk image and want an extracted file
for another tool. For XZ, it reads the uncompressed size from the index, creates
a suitable RAM disk, and decompresses directly into it:

```sh
ramstage ~/Downloads/board.img.xz
# Prints the completed file path: /Volumes/RAMStage/board.img
```

The original compressed file is preserved. The result is a regular file on
`/Volumes/RAMStage`: the partitions inside the image are not mounted, and no
device is flashed by these commands.

Only the completed file path goes to stdout. Progress and status go to stderr,
so the path can be captured for another command:

```sh
image=$(ramstage ~/Downloads/board.img.xz) && shasum -a 256 "$image"
```

Keep the volume mounted until the consuming tool has finished. Then discard it:

```sh
ramunstage
```

### Formats and size selection

Compression is detected from file contents, rather than the extension.

| Input compression | Size selection | Example |
| --- | --- | --- |
| XZ | Automatic, or override with `--size` | `ramstage board.img.xz` |
| gzip | `--size` required | `ramstage --size 4g board.img.gz` |
| bzip2 | `--size` required | `ramstage --size 4g board.img.bz2` |
| Zstandard | `--size` required | `ramstage --size 4g board.img.zst` |

`--size` always takes priority, including for XZ:

```sh
ramstage --size 6g ~/Downloads/board.img.xz
```

It specifies the **total RAM disk capacity**, including filesystem overhead.
Choose a size larger than the extracted file. There is no preliminary
decompression pass to count bytes.

Automatic XZ sizing reserves the larger of 16 MiB or 1% for the filesystem,
then rounds upward to whole MiB for files below 1 GiB, or whole GiB for larger
files. An image of exactly 4 GiB therefore gets a 5 GiB RAM disk.

Only supported compressed files are accepted. Plain `.img`/`.iso` files and ZIP
archives are rejected. No IMG/ISO content validation is performed: a supported
compressed input becomes one extracted file. A recognized compression suffix is
removed from the filename; otherwise `.unpacked` is appended.

## Commands and behavior

| Command | Result |
| --- | --- |
| `ramdisk mount 4g` | Create an empty disk at `/Volumes/RAMDisk` |
| `ramdisk umount` | Discard the empty-disk workflow's volume and its files |
| `ramstage [--size 4g] FILE` | Decompress FILE into `/Volumes/RAMStage` |
| `ramunstage` | Discard the staged volume and its extracted file |

One volume of each kind can exist at a time; the two workflows are independent.
Both support `--help` and `--version`. `ramdisk unmount` is also accepted.

macOS `diskutil` supplies the formatting and mounting progress output.
Unmounting checks the recorded volume UUID and does not force-eject a busy disk.
If a disk is busy, close its files and leave any shell working inside it before
retrying. `ramstage` attempts to remove its newly created RAM disk if
decompression fails or is interrupted. If cleanup fails, close open files and
retry `ramunstage`.

## Update or uninstall

```sh
brew update
brew upgrade ramdisk
```

To remove the package, first unmount any volumes you no longer need, then run:

```sh
brew uninstall ramdisk
```

## Run from source

For development, run `./ramdisk`, `./ramstage`, and `./ramunstage` directly from
the checkout. Install `xz` and `zstd` separately if you need those formats.

Alternatively, `sudo make install` links the commands into `/usr/local/bin`;
`sudo make uninstall` removes those links. Keep the checkout in place while
using them. `make install PREFIX="$HOME/.local"` supports a custom prefix whose
`bin` directory is already on your PATH. Use the same prefix to uninstall.
Remove development links before switching to Homebrew installation.

## License

MIT. See [LICENSE](LICENSE).
