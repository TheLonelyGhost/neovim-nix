ifndef NIX
  NIX := nix
endif
ifndef STATIX
  STATIX := $(NIX) run nixpkgs\#statix --
endif

.PHONY: test
test:
	$(STATIX) check
	$(NIX) flake check
	$(NIX) build --no-link '.#neovim'
