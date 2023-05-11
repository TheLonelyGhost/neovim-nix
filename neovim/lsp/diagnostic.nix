{ pkgs, lsp, ... }:

let
  utils = import ./utils.nix { inherit pkgs; };

  ruffConfig = ../../config/ruff.toml;

  statix-check = import ../../packages/statix-check { inherit pkgs lsp; };

  #
  # THIS IS THE SECTION YOU WANT TO MODIFY {{
  allLinters = {
    # @see: https://github.com/iamcco/diagnostic-languageserver/wiki/Linters
    ruff = {
      # meta
      package = lsp.ruff;
      filetypes = [ "python" ];

      # direct translation
      command = "ruff";
      args = [ "--format" "json" "--config" ruffConfig "--stdin-filename" "%filepath" "-" ];
      debounce = 100;
      sourceName = "ruff";
      parseJson = {
        sourceName = "filename";
        line = "location.row";
        column = "location.column";
        endLine = "end_location.row";
        endColumn = "end_location.column";
        message = ''[''${code}] ''${message}'';
      };
      # securities = {
      #   undefined = "warning";
      # };
    };
    golangci-lint = {
      # meta
      package = lsp.golangci-lint;
      filetypes = [ "go" "gomod" ];

      # direct translation
      command = "golangci-lint";
      args = [ "run" "--out-format" "json" ];
      rootPatterns = [ ".git" "go.mod" ];
      debounce = 100;
      sourceName = "golangci-lint";
      parseJson = {
        sourceName = "Pos.Filename";
        sourceNameFilter = true;
        errorsRoot = "Issues";
        line = "Pos.Line";
        column = "Pos.Column";
        message = ''[''${FromLinter}] ''${Text}'';
      };
    };
    hadolint = {
      # meta
      package = lsp.hadolint;
      filetypes = [ "dockerfile" ];

      # direct translation
      command = "hadolint";
      args = [ "-f" "json" "-" ];
      rootPatterns = [ ".hadolint.yaml" ];
      sourceName = "hadolint";
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
    statix = {
      # meta
      package = lsp.statix;
      filetypes = [ "nix" ];

      # direct translation
      command = "statix-check";
      args = [ "--format" "json" "--stdin" ];
      sourceName = "statix";
      debounce = 100;
      parseJson = {
        # sourceName = "file";
        errorsRoot = "report";
        line = "diagnostics[0].at.from.line";
        column = "diagnostics[0].at.from.column";
        endLine = "diagnostics[0].at.to.line";
        endColumn = "diagnostics[0].at.to.column";
        message = "\${diagnostics[0].message}";
        security = "severity";
      };
      securities = {
        Warn = "warning";
        Error = "error";
        Hint = "hint";
      };
    };
    rubocop = {
      # meta
      package = lsp.rubocop;
      filetypes = [ "ruby" "erb" ];

      # direct translation
      command = "rubocop";
      args = [ "--format" "json" "--force-exclusion" "--stdin" "%filepath" ];
      rootPatterns = [ ".git" "go.mod" ];
      debounce = 100;
      sourceName = "rubocop";
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
    shellcheck = {
      # meta
      package = lsp.shellcheck;
      filetypes = [ "sh" ];

      # direct translation
      command = "shellcheck";
      debounce = 100;
      args = [ "--format=json" "-" ];
      # offsetLine = 0;
      # offsetColumn = 0;
      sourceName = "shellcheck";
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
    standard = {
      # meta
      package = lsp.standard;
      filetypes = [ "javascript" ];

      # direct translation
      command = "standard";
      args = [ "--stdin" "--verbose" ];
      isStdErr = false;
      isStdOut = true;
      rootPatterns = [ ".git" ];
      debounce = 100;
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = "standardjs";
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
    ts-standard = {
      # meta
      package = lsp.ts-standard;
      filetypes = [ "typescript" ];

      # direct translation
      command = "ts-standard";
      args = [ "--stdin" "--verbose" ];
      isStdErr = false;
      isStdOut = true;
      rootPatterns = [ ".git" ];
      debounce = 100;
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = "ts-standard";
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
    vale = {
      # meta
      package = lsp.vale;
      filetypes = [ "markdown" ];

      # direct translation
      command = "vale";
      debounce = 100;
      args = [ "--no-exit" "--output" "JSON" "--ext" ".md" ];
      sourceName = "vale";
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
    vint = {
      # meta
      package = lsp.vint;
      filetypes = [ "vim" ];

      # direct translation
      command = "vint";
      debounce = 100;
      args = [ "--enable-neovim" "-f" "{file_path}:{line_number}:{column_number}: {severity}! {description}" "-" ];
      offsetLine = 0;
      offsetColumn = 0;
      sourceName = "vint";
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
    ruff = {
      # meta
      package = lsp.ruff;
      filetypes = [ "python" ];

      # direct translation
      command = "ruff";
      args = [ "--format" "json" "--config" ruffConfig "--stdin-filename" "%filepath" "--fix" "-" ];
    };
    statix = {
      # meta
      package = lsp.statix;
      filetypes = [ "nix" ];

      # direct translation
      command = "statix";
      args = [ "fix" "--stdin" ];
    };
    yapf = {
      # meta
      package = lsp.yapf;
      filetypes = [ "python" ];

      # direct translation
      command = "yapf";
      args = [ "--quiet" ];
    };
  };
  # }}
  #

  linters = utils.filterSupportedTools allLinters;
  linterFiletypes = utils.flipForFiletypes linters;
  formatters = utils.filterSupportedTools allFormatters;
  formatterFiletypes = utils.flipForFiletypes formatters;

  filetypesSupported = pkgs.lib.unique
    (builtins.concatLists [
      (builtins.attrNames linterFiletypes)
      (builtins.attrNames formatterFiletypes)
    ]);

  config = {
    cmd = [ "${lsp.diagnostic-language-server}/bin/diagnostic-languageserver" "--stdio" "--log-level" "4" ];
    filetypes = filetypesSupported;
    init_options = {
      linters = pkgs.lib.mapAttrs (_: utils.configLinter) linters;
      filetypes = linterFiletypes;
      formatters = pkgs.lib.mapAttrs (_: utils.configFormatter) formatters;
      formatFiletypes = formatterFiletypes;
    };
  };
in
{
  inherit linters formatters;

  buildInputs = (utils.collectBuildInputs linters) ++ (utils.collectBuildInputs formatters);

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
