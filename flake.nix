{
  description = "Neovim in a box";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.flake-compat = {
    url = "github:edolstra/flake-compat";
    flake = false;
  };
  inputs.lsp-nix.url = "github:thelonelyghost/lsp-nix";

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

        suggestedPlugins = import ./neovim/plugin-manifest.nix {
          inherit pkgs lsp;

          neovimPlugins = {
            # put any other packages for vim plugins, managed by
            # this flake, in this attribute set so we can make it
            # available as part of the `manifest` array.
          };
        };

        customized = import ./neovim {
          inherit pkgs pluginUtils;
        };

        # some default neovim config
        neovim = customized {
          plugins = suggestedPlugins;
        };
      in
      {
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.bashInteractive
            pkgs.gnumake
          ];
          buildInputs = [
          ];
        };

        packages = {
          inherit customized neovim pluginUtils suggestedPlugins;
        };
        defaultPackage = neovim;
      });
}
