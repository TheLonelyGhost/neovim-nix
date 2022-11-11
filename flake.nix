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

        pluginUtils = import ./neovim/plugin-utils.nix {
          inherit pkgs;
        };

        lsp = lsp-nix.outputs.packages."${system}";

        managedPlugins = import ./plugins {
          inherit pkgs;
        };

        suggestedPlugins = import ./neovim/plugin-manifest.nix {
          inherit pkgs lsp;

          neovimPlugins = {
            # put any other packages for vim plugins, managed by
            # this flake, in this attribute set so we can make it
            # available as part of the `manifest` array.
            inherit (managedPlugins) thelonelyghost-defaults;
          };
        };

        customized = import ./neovim {
          inherit pkgs pluginUtils;
        };

        # some default neovim config
        # neovim = customized {
        #   plugins = suggestedPlugins;
        # };

        neovim = pkgs.neovim-unwrapped;
      in
      {
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bashInteractive
            pkgs.gnumake
          ];
          buildInputs = [
          ];
        };

        packages = {
          # inherit customized neovim pluginUtils suggestedPlugins;
          inherit neovim;

          default = neovim;
        };
      });
}
