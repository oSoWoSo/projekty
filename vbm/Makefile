PREFIX_BIN ?= /bin
PREFIX_BASHC ?= /usr/share/bash-completion/completions

.PHONY: all
all:
	@echo 'nothing to do'

.PHONY: install
install:
	cp vbm.sh $(PREFIX_BIN)/vbm
	cp bash-completion/completions/vbm $(PREFIX_BASHC)/vbm

.PHONY: uninstall
uninstall:
	rm -f $(PREFIX_BIN)/vbm
	rm -f $(PREFIX_BASHC)/vbm

.PHONY: check
check:
	which vbm
