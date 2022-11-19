{ pkgs, lsp, ... }:

let
  utils = import ./utils.nix { inherit pkgs; };

  #
  # THIS IS THE SECTION YOU WANT TO MODIFY {{
  allLinters = {
    # @see: https://github.com/iamcco/diagnostic-languageserver/wiki/Linters
    flake8 = rec {
      # meta
      package = lsp.flake8;
      filetypes = [ "python" ];

      # direct translation
      command = "${package}/bin/flake8";
      args = ["--format" "%(row)d,%(col)d,%(code).1s,%(code)s: %(text)s" "-"];
      debounce = 100;
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = package.pname;
      formatLines = 1;
      formatPattern = [
        ''(\\d+),(\\d+),([A-Z]),(.*)(\\r|\\n)*$''
        {
          line = 1;
          column = 2;
          security = 3;
          message = 4;
        }
      ];
      securities = {
        W = "warning";
        E = "error";
        F = "error";
        C = "error";
        N = "error";
      };
    };
    golangci-lint = rec {
      # meta
      package = lsp.golangci-lint;
      filetypes = [ "go" "gomod" ];

      # direct translation
      command = "${package}/bin/golangci-lint";
      args = [ "run" "--out-format" "json" ];
      rootPatterns = [ ".git" "go.mod" ];
      debounce = 100;
      sourceName = package.pname;
      parseJson = {
        sourceName = "Pos.Filename";
        sourceNameFilter = true;
        errorsRoot = "Issues";
        line = "Pos.Line";
        column = "Pos.Column";
        message = ''[''${FromLinter}] ''${Text}'';
      };
    };
    hadolint = rec {
      # meta
      package = lsp.hadolint;
      filetypes = [ "dockerfile" ];

      # direct translation
      command = "${package}/bin/hadolint";
      args = [ "-f" "json" "-" ];
      rootPatterns = [ ".hadolint.yaml" ];
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
    nix-linter = rec {
      # meta
      package = lsp.nix-linter;
      filetypes = [ "nix" ];

      # direct translation
      command = "${package}/bin/nix-linter";
      sourceName = package.pname;
      debounce = 100;
      parseJson = {
        line = "pos.spanBegin.sourceLine";
        column = "pos.spanBegin.sourceColumn";
        endLine = "pos.spanEnd.sourceLine";
        endColumn = "pos.spanEnd.sourceColumn";
        message = ''''${description}'';
      };
      securities = {
        undefined = "warning";
      };
    };
    rubocop = rec {
      # meta
      package = lsp.rubocop;
      filetypes = [ "ruby" "erb" ];

      # direct translation
      command = "${package}/bin/rubocop";
      args = [ "--format" "json" "--force-exclusion" "--stdin" "%filepath" ];
      rootPatterns = [ ".git" "go.mod" ];
      debounce = 100;
      sourceName = if package ? pname then package.pname else "rubocop";
      parseJson = {
        errorsRoot = "files[0].offenses";
        line = "location.start_line";
        endLine = "location.end_line";
        column = "location.start_column";
        endColumn = "location.end_column";
        message = ''[''${cop_name}] ''${message}'';
        security = "severity";
      };
      securities = {
        fatal = "error";
        error = "error";
        warning = "warning";
        convention = "info";
        refactor = "info";
        info = "info";
      };
    };
    shellcheck = rec {
      # meta
      package = lsp.shellcheck;
      filetypes = [ "sh" ];

      # direct translation
      command = "${package}/bin/shellcheck";
      debounce = 100;
      args = [ "--format=json" "-" ];
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
    standard = rec {
      # meta
      package = lsp.standard;
      filetypes = [ "javascript" ];

      # direct translation
      command = "${package}/bin/standard";
      args = [ "--stdin" "--verbose" ];
      isStdErr = false;
      isStdOut = true;
      rootPatterns = [ ".git" ];
      debounce = 100;
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = if package ? pname then package.pname else "standardjs";
      formatLines = 1;
      formatPattern = [
        ''^\\s*<\\w+>:(\\d+):(\\d+):\\s+(.*)(\\r|\\n)*$''
        {
          line = 1;
          column = 2;
          message = 3;
        }
      ];
    };
    ts-standard = rec {
      # meta
      package = lsp.ts-standard;
      filetypes = [ "typescript" ];

      # direct translation
      command = "${package}/bin/ts-standard";
      args = [ "--stdin" "--verbose" ];
      isStdErr = false;
      isStdOut = true;
      rootPatterns = [ ".git" ];
      debounce = 100;
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = if package ? pname then package.pname else "ts-standard";
      formatLines = 1;
      formatPattern = [
        ''^\\s*<\\w+>:(\\d+):(\\d+):\\s+(.*)(\\r|\\n)*$''
        {
          line = 1;
          column = 2;
          message = 3;
        }
      ];
    };
    vale = rec {
      # meta
      package = lsp.vale;
      filetypes = [ "markdown" ];

      # direct translation
      command = "${package}/bin/vale";
      debounce = 100;
      args = [ "--no-exit" "--output" "JSON" "--ext" ".md" ];
      sourceName = package.pname;
      parseJson = {
        errorsRoot = "stdin.md";
        # sourceName = "file";
        line = "Line";
        column = "Span[0]";
        endLine = "Line";
        endColumn = "Span[1]";
        message = ''''${Message}\n''${Link}'';
        security = "Severity";
      };
      securities = {
        error = "error";
        warning = "warning";
        suggestion = "info";
      };
    };
    vint = rec {
      # meta
      package = lsp.vint;
      filetypes = [ "vim" ];

      # direct translation
      command = "${package}/bin/vint";
      debounce = 100;
      args = [ "--enable-neovim" "-f" "{file_path}:{line_number}:{column_number}: {severity}! {description}" "-" ];
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = package.pname;
      formatLines = 1;
      formatPattern = [
        ''[^:]+:(\\d+):(\\d+):\\s*([^!]*)! (.*)(\\r|\\n)*$''
        {
          line = 1;
          column = 2;
          security = 3;
          message = 4;
        }
      ];
      securities = {
        error = "error";
        warning = "warning";
        style_problem = "info";
      };
    };
  };
  allFormatters = {
    # @see: https://github.com/iamcco/diagnostic-languageserver/wiki/Formatters
    isort = rec {
      # meta
      package = lsp.isort;
      filetypes = [ "python" ];

      # direct translation
      command = "${package}/bin/isort";
      args = [ "--quiet" "-" ];
    };
    yapf = rec {
      # meta
      package = lsp.yapf;
      filetypes = [ "python" ];

      # direct translation
      command = "${package}/bin/yapf";
      args = [ "--quiet" ];
    };
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

  configLinter = tool:
    pkgs.lib.filterAttrs (n: v: n != "package" && n != "filetypes") tool;

  configFormatter = tool:
    pkgs.lib.filterAttrs (n: v: n != "package" && n != "filetypes") tool;

  config = {
    cmd = [ "${lsp.diagnostic-language-server}/bin/diagnostic-languageserver" "--stdio" ];
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
