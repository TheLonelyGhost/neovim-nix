{ pkgs, ... }:

let
  lib = import ../../libs/plugin-utils.nix { inherit pkgs; };
in
{
  inherit (lib) toLua;

  isSupportedLang = tools: lang:
    builtins.elem lang (builtins.attrNames tools);

  collectBuildInputs = tools:
    pkgs.lib.unique (builtins.map (k: v: v.package) tools);

  filterSupportedTools = tools:
    pkgs.lib.filterAttrs (k: v: lib.isSupportedDrv v.package) tools;
}
