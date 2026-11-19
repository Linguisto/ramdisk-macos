#!/bin/bash
# Install links to this checkout; updates to the checkout take effect immediately.
set -euo pipefail

action=${1:-install}
prefix=${2:-/usr/local}
case "$action" in install|uninstall) ;; *) echo 'Usage: install.sh install|uninstall [prefix]' >&2; exit 1 ;; esac
[[ $# -le 2 && "$prefix" == /* ]] || { echo 'Prefix must be an absolute path.' >&2; exit 1; }
source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
bindir="${prefix%/}/bin"
commands=(ramdisk ramstage ramunstage)

# Check all names before changing anything; never replace another program.
for command in "${commands[@]}"; do
  link="$bindir/$command"
  target="$source_dir/$command"
  if [[ -e "$link" || -L "$link" ]]; then
    if [[ ! -L "$link" || $(readlink "$link") != "$target" ]]; then
      printf 'Refusing to change an unrelated file: %s\n' "$link" >&2
      exit 1
    fi
  fi
done

if [[ $action == install ]]; then
  for command in "${commands[@]}"; do
    [[ -x "$source_dir/$command" ]] || { echo "Missing executable: $command" >&2; exit 1; }
  done
  mkdir -p "$bindir"
  for command in "${commands[@]}"; do
    link="$bindir/$command"
    if [[ ! -L "$link" ]]; then
      ln -s "$source_dir/$command" "$link"
    fi
    printf '%s -> %s\n' "$link" "$source_dir/$command"
  done
else
  for command in "${commands[@]}"; do
    link="$bindir/$command"
    if [[ -L "$link" ]]; then
      rm "$link"
      printf 'Removed %s\n' "$link"
    fi
  done
fi
