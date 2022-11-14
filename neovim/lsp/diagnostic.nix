{ pkgs, lsp, ... }:

let
  utils = import ./utils.nix { inherit pkgs; };

  #
  # THIS IS THE SECTION YOU WANT TO MODIFY {{
  allLinters = {
    # @see: https://github.com/iamcco/diagnostic-languageserver/wiki/Linters
    hadolint = rec {
      # meta
      package = pkgs.hadolint;
      filetypes = ["dockerfile"];

      # direct translation
      command = "${package}/bin/hadolint";
      args = ["-f" "json" "-"];
      rootPatterns = [".hadolint.yaml"];
      sourceName = package.pname;
      parseJson = {
        line = "line";
        column = "column";
        security = "level";
        message = ''[''${code}] ''${message}'';
      };
      securities = {
        error = "error";
        warning = "warning";
        info = "info";
        style = "hint";
      };
    };
    languagetool = rec {
      # meta
      package = pkgs.languagetool;
      filetypes = ["markdown"];

      # direct translation
      command = "${package}/bin/languagetool";
      debounce = 200;
      args = ["-"];
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = package.pname;
      formatLines = 2;
      formatPattern = [
        ''^\d+?\.\)\s+Line\s+(\d+),\s+column\s+(\d+),\s+([^\n]+)\nMessage:\s+(.*)(\r|\n)*$''
        {
          line = 1;
          column = 2;
          message = [4 3];
        }
      ];
    };
    shellcheck = rec {
      # meta
      package = lsp.shellcheck;
      filetypes = ["sh"];

      # direct translation
      command = "${package}/bin/shellcheck";
      debounce = 100;
      args = ["--format=json" "-"];
      # offsetLine = 0;
      # offsetColumn = 0;
      sourceName = package.pname;
      # formatLines = 1;
      parseJson = {
        # sourceName = "file";
        line = "line";
        column = "column";
        endLine = "endLine";
        endColumn = "endColumn";
        message = ''[SC''${code}] ''${message}'';
        security = "level";
      };
      securities = {
        error = "error";
        warning = "warning";
        note = "info";
        sytle = "hint";
      };
    };
  };
  allFormatters = {
    # @see: https://github.com/iamcco/diagnostic-languageserver/wiki/Formatters
  };
  # }}
  #

  linters = utils.filterSupportedTools allLinters;
  linterFiletypes = flipForFiletypes linters;
  formatters = utils.filterSupportedTools allFormatters;
  formatterFiletypes = flipForFiletypes formatters;

  filetypesSupported = pkgs.lib.unique
    (builtins.concatLists [
      (builtins.attrNames linterFiletypes)
      (builtins.attrNames formatterFiletypes)
    ]);

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
        { "${v}" = k; } ;

      # filetypePairings { a = { filetypes = ["sh", "text"]; }; b = { filetypes = ["go"]; }; }
      # => [{ sh = "a"; } { text = "a"; } { go = "b"; }]
      filetypePairings = set:
        pkgs.lib.flatten (pkgs.lib.mapAttrsToList (name: value:
          builtins.map (v: { "${v}" = name; }) value.filetypes
        ) set);

      # flippedPairings [{ sh = "a"; } { text = "a"; } { go = "b"; }]
      # => { sh = "a"; text = "a"; go = "b"; }
      flippedPairings = sets:
        builtins.mapAttrs (name: value: builtins.head value) (pkgs.lib.zipAttrs sets);
    in
    flippedPairings (filetypePairings tools);

  configLinter = tool:
    pkgs.lib.filterAttrs (n: v: n != "package" && n != "filetypes") tool;

  configFormatter = tool:
    pkgs.lib.filterAttrs (n: v: n != "package" && n != "filetypes") tool;

  config = {
    cmd = ["${lsp.diagnostic-language-server}/bin/diagnostic-languageserver" "--stdio"];
    filetypes = filetypesSupported;
    init_options = {
      linters = pkgs.lib.mapAttrs (name: value: configLinter value) linters;
      filetypes = linterFiletypes;
      formatters = pkgs.lib.mapAttrs (name: value: configFormatter value) formatters;
      formatFiletypes = formatterFiletypes;
    };
  };
in
{
  inherit linters formatters;

  config = ''
  -- Language: Diagnostics
  lspconfig['diagnosticls'].setup(${utils.toLua config})

  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics,
    {
      -- float = true,
      update_in_insert = true,
      severity_sort = true,
    }
  )
  '';
}
