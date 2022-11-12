{ pkgs, lsp, ... }:

let
  pluginUtils = import ../libs/plugin-utils.nix { inherit pkgs; };

  plugins = pluginUtils.normalizePlugins (import ./plugins.nix { inherit pkgs lsp; });

  neovimConfig = pkgs.neovimUtils.makeNeovimConfig { inherit plugins; };

  neovim = pkgs.neovim.override {
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
