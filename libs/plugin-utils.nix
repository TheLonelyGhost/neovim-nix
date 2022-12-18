{ pkgs, ... }:

let
  isSupportedDrv = drv:
    (builtins.elem pkgs.system drv.meta.platforms) && (if drv.meta ? broken then !drv.meta.broken else true);

  toLua = obj:
    "vim.json.decode([[ " + (builtins.toJSON obj) + " ]])";


  /* Plugins are assumed to adhere to the following schema, denoted as
     <plugin-attrset> hereafter:

         {
           plugin = <derivation>;  # REQUIRED
           config = <viml-string>;
           buildInputs = [<derivation> ...];
           nativeBuildInputs = [<derivation> ...];
         }

     `plugin` represents the vim-plugin formatted nix package.

     `config` is a string whose configuration will be observed if the
     plugin is loaded.

     `buildInputs` and `nativeBuildInputs` contain packages that will be
     added to the neovim `buildInputs` and `nativeBuildInputs` respectively.
     This is generally used if a neovim plugin has a native package that
     must be available at compile time (`nativeBuildInputs`) of neovim or at
     runtime (`buildInputs`) in the PATH.
  */

  isValidPluginAttrset = plug:
    pkgs.lib.all (x: x) (
      # required attributes checks {{
      [
        (plug ? plugin)
      ]
      # }}
      ++
      # type checks {{ 
      (pkgs.lib.optionals (plug ? plugin) [
        (pkgs.lib.isDerivation plug)
      ])
      ++
      (pkgs.lib.optionals (plug ? config) [
        (isValidConfig plug.config)
      ])
      ++
      (pkgs.lib.optionals (plug ? buildInputs) [
        pkgs.lib.all pkgs.lib.isDerivation plug.buildInputs
      ])
      ++
      (pkgs.lib.optionals (plug ? nativeBuildInputs) [
        pkgs.lib.all pkgs.lib.isDerivation plug.nativeBuildInputs
      ])
      # }}
    );

  isValidConfig = builtins.isString;

  /* Ensures a single plugin adheres to the plugin-attrset schema under
     the following circumstances:

     1. it must have a `plugin` attribute, at which point all optional
        attributes will be set to their default values so we can rely
        on a specific structure.
     2. if not (1), assume the given item is a package (derivation) and
        assign it to `plugin` attribute, following the rest of the
        logic in (1) accordingly.
  */
  normalize = x:
    # Default values for optional attributes
    {
      optional = false;
      config = "";
      buildInputs = [ ];
      nativeBuildInputs = [ ];
    } //
    # If no `plugin` attribute, must be a bare package
    (if x ? plugin then x else { plugin = x; });

  /* Transforms a list of plugins in a way that validates with
     `isValidPluginAttrset`.

         plugins = normalizePlugins myManifest;
  */
  normalizePlugins = builtins.map normalize;
in
{
  inherit normalizePlugins isValidPluginAttrset;

  inherit isSupportedDrv toLua;
}
