.PHONY: test

test:
	nix flake check
	nix build '.#neovim' && rm -f ./result
