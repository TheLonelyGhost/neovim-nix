{ pkgs, ... }:

let
  isSupportedDrv = drv:
    builtins.elem pkgs.system drv.meta.platforms;
in
{
  listToLisp = set:
    "{'" + (builtins.concatStringsSep "', '" set) + "'}";

  isSupportedLang = tools: lang:
    builtins.elem lang (builtins.attrNames tools);

  collectBuildInputs = tools:
    pkgs.lib.unique (builtins.map (k: v: v.package) tools);

  filterSupportedTools = tools:
    pkgs.lib.filterAttrs (k: v: isSupportedDrv v.package) tools;
}
