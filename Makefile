NIX := nix
STATIX := $(NIX) run nixpkgs\#statix --

.PHONY: test

test:
	$(STATIX) check
	$(NIX) flake check
	$(NIX) build '.#neovim' && rm -f ./result
