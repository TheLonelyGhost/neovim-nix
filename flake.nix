{
  description = "Neovim in a box";
  inputs = {
    nixpkgs.url = "flake:nixpkgs";

    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;

    lsp-nix.url = "github:thelonelyghost/lsp-nix";
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, lsp-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # config.allowUnfree = true;
        };
        lsp = lsp-nix.outputs.packages."${system}";

        neovim = import ./neovim { inherit pkgs lsp; };
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
