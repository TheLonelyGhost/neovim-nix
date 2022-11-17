{
  description = "Neovim in a box";
  inputs = {
    nixpkgs.url = "flake:nixpkgs";

    flake-utils.url = "flake:flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    overlays.url = "github:thelonelyghost/blank-overlay-nix";

    lsp-nix.url = "github:thelonelyghost/lsp-nix";
    lsp-nix.inputs.overlays.follows = "overlays";
    lsp-nix.inputs.flake-utils.follows = "flake-utils";
    tree-sitter-nix.url = "github:thelonelyghost/tree-sitter-nix";
    tree-sitter-nix.inputs.overlays.follows = "overlays";
    tree-sitter-nix.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, overlays, lsp-nix, tree-sitter-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # config.allowUnfree = true;
          overlays = [overlays.overlays.default];
        };
        lsp = lsp-nix.outputs.packages."${system}";
        tree-sitter = tree-sitter-nix.outputs.packages."${system}";

        neovim = import ./neovim { inherit pkgs lsp tree-sitter; };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bashInteractive
            pkgs.gnumake
          ];
          buildInputs = [
            neovim
          ];
        };

        packages = {
          inherit neovim;

          default = neovim;
        };
      });
}
