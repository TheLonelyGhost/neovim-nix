{ pkgs, pluginUtils, ... }:

{plugins ? [], customRc ? "", extraName ? "thelonelyghost"}:

let
  normalizedPlugins = pluginUtils.processPlugins plugins;

  # shouldn't need to filter and map this since they should be
  # normalized, but `nix flake check` complains about a possible
  # lack of attribute so... there.
  pluginPackages = pkgs.lib.remove null (map (x: if x ? plugin then x.plugin else null) normalizedPlugins);

  pluginBuildInputs = pkgs.lib.unique (pkgs.lib.foldl (a: b:
    let
      depsA = if builtins.isList a then a # maybe this is the aggregate of our work so far
        else if a ? buildInputs then a.buildInputs
        else [];
      depsB = if builtins.isList b then b
        else if b ? buildInputs then b.buildInputs
        else [];
    in
    depsA ++ depsB
    ) [] normalizedPlugins);

  pluginNativeBuildInputs = pkgs.lib.unique (pkgs.lib.foldl (a: b:
    let
      depsA = if a != null && a ? nativeBuildInputs then a.nativeBuildInputs else [];
      depsB = if b != null && b ? nativeBuildInputs then b.nativeBuildInputs else [];
    in
    (depsA ++ depsB)
  ) [] normalizedPlugins);

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
    customRc = customRc;
  };

  neovimBasePackage = pkgs.neovim-unwrapped.overrideAttrs (oldAttrs: {
    buildInputs = (if oldAttrs ? buildInputs then oldAttrs.buildInputs else []) ++ pluginBuildInputs;
    nativeBuildInputs = (if oldAttrs ? nativeBuildInputs then oldAttrs.nativeBuildInputs else []) ++ pluginNativeBuildInputs;
  });
in
pkgs.wrapNeovimUnstable neovimBasePackage {
  inherit extraName;

  inherit (neovimConfig) neovimRcContent python3Env rubyEnv luaEnv withNodeJs;

  vimAlias = true;
  viAlias = true;
}
