{ pkgs, lsp, tree-sitter, ... }:

let
  pluginUtils = import ../libs/plugin-utils.nix { inherit pkgs; };

  plugins = pluginUtils.normalizePlugins (import ./plugins.nix { inherit pkgs lsp tree-sitter; });

  neovimConfig = pkgs.neovimUtils.makeNeovimConfig { inherit plugins; };

  neovim = pkgs.neovim.override {
    vimAlias = true;
    viAlias = true;

    configure = {
      customRC = neovimConfig.neovimRcContent;
      packages.thelonelyghost = {
        start = builtins.map (p: p.plugin) plugins;
        opt = [];
      };
    };
  };
in
assert pkgs.lib.all (x: pluginUtils.isValidPluginAttrset x) plugins -> throw "Invalid format in plugins list";
neovim
