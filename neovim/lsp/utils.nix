{ pkgs, ... }:

let
  lib = import ../../libs/plugin-utils.nix { inherit pkgs; };

  configLinter = tool:
    pkgs.lib.filterAttrs (n: v: n != "package" && n != "filetypes") tool;

  configFormatter = tool:
    pkgs.lib.filterAttrs (n: v: n != "package" && n != "filetypes") tool;

  /*
    Grabs the filetype field of each tool and makes it
    the key in an attrset, setting the value to the key
    off the previous attrset.

    Example:

    flipForFiletypes { a = { filetypes = ["sh", "text"]; }; b = { filetypes = ["go"]; }; }
    => { sh = "a"; text = "a"; go = "b"; }
  */
  flipForFiletypes = tools:
    let
      # flipKeyWithValue { a = "b"; }
      # => { b = "a"; }
      flipKeyWithValue = k: v:
        { "${v}" = k; };

      # filetypePairings { a = { filetypes = ["sh", "text"]; }; b = { filetypes = ["go"]; }; }
      # => [{ sh = "a"; } { text = "a"; } { go = "b"; }]
      filetypePairings = set:
        pkgs.lib.flatten (pkgs.lib.mapAttrsToList
          (name: value:
            builtins.map (v: { "${v}" = name; }) value.filetypes
          )
          set);

      # flippedPairings [{ sh = "a"; } { text = "a"; } { go = "b"; }]
      # => { sh = "a"; text = "a"; go = "b"; }
      flippedPairings = sets:
        builtins.mapAttrs (name: value: builtins.head value) (pkgs.lib.zipAttrs sets);
    in
    flippedPairings (filetypePairings tools);

in
{
  inherit (lib) toLua;

  inherit flipForFiletypes configLinter configFormatter;

  isSupportedLang = tools: lang:
    builtins.elem lang (builtins.attrNames tools);

  collectBuildInputs = tools:
    pkgs.lib.unique (builtins.map (k: v: v.package) tools);

  filterSupportedTools = tools:
    pkgs.lib.filterAttrs (k: v: lib.isSupportedDrv v.package) tools;
}
