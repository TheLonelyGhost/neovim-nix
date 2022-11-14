{
  description = "Neovim in a box";
  inputs = {
    nixpkgs.url = "flake:nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    lsp-nix.url = "github:thelonelyghost/lsp-nix";
    tree-sitter-nix.url = "github:thelonelyghost/tree-sitter-nix";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, lsp-nix, tree-sitter-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # config.allowUnfree = true;
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
