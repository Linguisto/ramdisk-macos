PREFIX ?= /usr/local

.PHONY: install uninstall help

install:
	/bin/bash ./install.sh install "$(PREFIX)"

uninstall:
	/bin/bash ./install.sh uninstall "$(PREFIX)"

help:
	@echo 'sudo make install                  Link commands into /usr/local/bin'
	@echo "sudo make uninstall                Remove only this checkout's links"
	@echo 'make install PREFIX=$$HOME/.local   Use a custom prefix'
