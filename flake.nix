{
  description = "Neovim in a box";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11-small";

    flake-utils.url = "flake:flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
    overlays.url = "github:thelonelyghost/blank-overlay-nix";

    lsp-nix = {
      url = "https://flakehub.com/f/TheLonelyGhost/lsp/*.tar.gz";
      inputs = {
        overlays.follows = "overlays";
        flake-utils.follows = "flake-utils";
        flake-compat.follows = "flake-compat";
      };
    };
  };

  outputs = { self, nixpkgs, flake-utils, flake-compat, overlays, lsp-nix }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          # config.allowUnfree = true;
          overlays = [overlays.overlays.default];
        };
        lsp = lsp-nix.outputs.packages."${system}";

        statix-check = import ./packages/statix-check {
          inherit pkgs lsp;
        };

        neovim = import ./neovim { inherit pkgs lsp; };
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bashInteractive
            pkgs.gnumake
            pkgs.statix
          ];

          STATIX = "${pkgs.statix}/bin/statix";

          buildInputs = [
            neovim
          ];
        };

        packages = {
          inherit neovim statix-check;

          default = neovim;
        };
      });
}
