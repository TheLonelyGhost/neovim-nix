{ pkgs, pluginUtils, ... }:

{plugins ? [], customRc ? "", extraName ? "thelonelyghost"}:

let
  normalizedPlugins = pluginUtils.processPlugins plugins;

  # shouldn't need to filter and map this since they should be
  # normalized, but `nix flake check` complains about a possible
  # lack of attribute so... there.
  pluginPackages = pkgs.lib.remove null (map (x: if x ? plugin then x.plugin else null) normalizedPlugins);

  neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
    plugins = normalizedPlugins;

    # Load the plugins as a native package in neovim
    configure.packages.thelonelyghost.start = pluginPackages;

    # Don't worry about `packloadall` since the plugin helper
    # for `neovimUtils.makeNeovimConfig` will add
    # `configure.packages.*` to the runtime path for neovim
    # prior to both the plugin-specific configs and this
    # customRc, which represents the overarching customizations
    # not assigned to a plugin.
    customRc = customRc + (builtins.readFile ./config/init.vim);
  };
in
pkgs.wrapNeovimUnstable pkgs.neovim-unwrapped {
  inherit extraName;

  inherit (neovimConfig) neovimRcContent python3Env rubyEnv luaEnv withNodeJs;

  vimAlias = true;
  viAlias = true;
}
