{ pkgs, lsp, tree-sitter, ... }:

let
  pluginUtils = import ../libs/plugin-utils.nix { inherit pkgs; };

  nvim-lsp = import ./lsp {
    inherit pkgs lsp;
  };
  pathSuffixes = pkgs.lib.makeBinPath nvim-lsp.builtInputs;

  plugins = pluginUtils.normalizePlugins (import ./plugins.nix { inherit pkgs lsp tree-sitter; });

  neovimConfig = pkgs.neovimUtils.makeNeovimConfig { inherit plugins; };

  neovim = pkgs.neovim.override {
    vimAlias = true;
    viAlias = true;

    extraMakeWrapperArgs = pkgs.lib.escapeShellArgs [
      "--suffix" "PATH" ":" (pkgs.lib.makeBinPath nvim-lsp.buildInputs)
    ];

    configure = {
      customRC = neovimConfig.neovimRcContent;
      packages.thelonelyghost = {
        start = builtins.map (p: p.plugin) plugins;
        opt = [];
      };
    };
  };
in
assert pkgs.lib.all pluginUtils.isValidPluginAttrset plugins -> throw "Invalid format in plugins list";
neovim
