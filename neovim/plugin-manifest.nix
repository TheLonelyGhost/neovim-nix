{ pkgs, lsp, neovimPlugins, ... }:

let
  isSupported = pkg:
    builtins.elem pkgs.system pkg.meta.platforms;

  allGrammars =
    # NOTE: left here in case the bundled grammars in pkgs.tree-sitter aren't as up-to-date
    # pkgs.lib.mapAttrsToList (name: value: value) (
    #   pkgs.lib.filterAttrs (name: value: name != "recurseForDerivations") pkgs.tree-sitter-grammars
    # );
    [ ];

  lspLanguages = [
    (pkgs.lib.optionalString (isSupported lsp.bash-language-server) "bash")
    (pkgs.lib.optionalString (isSupported lsp.scry) "crystal")
    (pkgs.lib.optionalString (isSupported lsp.stylelint-lsp) "css")
    (pkgs.lib.optionalString (isSupported lsp.dot-language-server) "graphviz")
    (pkgs.lib.optionalString (isSupported lsp.dockerfile-language-server) "docker")
    (pkgs.lib.optionalString (isSupported lsp.gopls) "go")
    (pkgs.lib.optionalString (isSupported lsp.vscode-langservers-extracted) "html")
    (pkgs.lib.optionalString (isSupported lsp.vscode-langservers-extracted) "json")
    (pkgs.lib.optionalString (isSupported lsp.nim-language-server) "nim")
    (pkgs.lib.optionalString (isSupported lsp.nix-language-server) "nix")
    (pkgs.lib.optionalString (isSupported lsp.pyright) "python")
    (pkgs.lib.optionalString (isSupported lsp.solargraph) "ruby")
    (pkgs.lib.optionalString (isSupported lsp.rust-analyzer) "rust")
    (pkgs.lib.optionalString (isSupported lsp.terraform-language-server) "terraform")
    (pkgs.lib.optionalString (isSupported lsp.typescript-language-server) "typescript")
    (pkgs.lib.optionalString (isSupported lsp.vim-language-server) "vim")
    (pkgs.lib.optionalString (isSupported lsp.yaml-language-server) "yaml")
  ];
in
[
  {
    plugin = pkgs.vimPlugins.editorconfig-vim;
  }
  {
    plugin = neovimPlugins.thelonelyghost-defaults;
  }
  {
    plugin = pkgs.vimPlugins.vim-gitgutter;
  }
  # Disabled because treesitter highlighting is faster/better for most syntaxes:
  # { plugin = pkgs.vimPlugins.vim-polyglot; }
  {
    plugin = pkgs.vimPlugins.nvim-treesitter-refactor;
  }
  {
    plugin = pkgs.vimPlugins.nvim-treesitter-context;
    config = ''
      lua <<EOH
      require'treesitter-context'.setup {
        enable = true,
        throttle = true,
        max_lines = 0, -- how many lines the window should span (Values <= 0 means no limit)
      }
      EOH
    '';
  }
  {
    plugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (plugins: pkgs.tree-sitter.allGrammars);
    buildInputs = [
      pkgs.tree-sitter
      pkgs.nodejs
      pkgs.gcc
      pkgs.git
    ];
    config = ''
      lua <<EOH
      require'nvim-treesitter.configs'.setup {
        refactor = {
          highlight_definitions = { enable = true },
          smart_rename = {
            enable = true,
            keymaps = {
              smart_rename = "grr",
            },
          },
          navigation = {
            enable = true,
            keymaps = {
              goto_definition_lsp_fallback = "gnd",
              list_definitions = "gnD",
              list_definitions_toc = "gO",
              goto_next_usage = "<a-*>",
              goto_previous_usage = "<a-#>",
            },
          },
        },
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      }
      EOH

      set foldmethod=expr
      set foldexpr=nvim_treesitter#foldexpr()
      set foldlevelstart=9
    '';
  }
  {
    plugin = pkgs.vimPlugins.vim-vsnip;
  }
  {
    plugin = pkgs.vimPlugins.vim-vsnip-integ;
  }
  {
    plugin = pkgs.vimPlugins.cmp-buffer;
  }
  {
    plugin = pkgs.vimPlugins.cmp-cmdline;
  }
  {
    plugin = pkgs.vimPlugins.cmp-path;
  }
  {
    plugin = pkgs.vimPlugins.cmp-nvim-lsp;
  }
  {
    plugin = pkgs.vimPlugins.nvim-cmp;
    config = ''
      " Handy stuff to display autocompletion, but not autoinsert
      set completeopt=menuone,noinsert,noselect

      " Skip entries related to insert completion menu events in `:messages`
      set shortmess+=c

      lua <<EOH
      local cmp = require'cmp'

      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'vsnip' },
        }, {
          { name = 'buffer' },
        }),
      })
      EOH
    '';
  }
  {
    plugin = pkgs.vimPlugins.lsp-status-nvim;
  }
  {
    plugin = pkgs.vimPlugins.gruvbox-community;
    config = ''
      let g:gruvbox_contrast_dark = 'hard'
      if exists('+termguicolors')
        let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum;"
        let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum;"
      endif
      let g:gruvbox_invert_selection = '0'
      colorscheme gruvbox
      set background=dark
    '';
  }
  {
    plugin = pkgs.vimPlugins.nvim-lspconfig;
    # config = "";
    config = (pkgs.lib.concatStringsSep "\n\n" [
      "lua <<EOH"
      (builtins.readFile ./configs/lspconfig-before.lua)
      (pkgs.lib.optionalString (builtins.elem "bash" lspLanguages) ''
        -- Bash
        nvim_lsp.bashls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.bash-language-server}/bin/bash-language-server', 'start' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "crystal" lspLanguages) ''
        -- Crystal
        nvim_lsp.scry.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.scry}/bin/scry' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "css" lspLanguages) ''
        -- CSS / SCSS
        nvim_lsp.stylelint_lsp.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.stylelint-lsp}/bin/stylelint-lsp', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "graphviz" lspLanguages) ''
        -- Graphviz (dot)
        nvim_lsp.dotls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.dot-language-server}/bin/dot-language-server', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "docker" lspLanguages) ''
        -- Docker
        nvim_lsp.dockerls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.dockerfile-language-server}/bin/docker-langserver', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "go" lspLanguages) ''
        -- Go
        nvim_lsp.gopls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.gopls}/bin/gopls' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "html" lspLanguages) ''
        -- HTML
        nvim_lsp.html.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.vscode-langservers-extracted}/bin/vscode-html-language-server', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "json" lspLanguages) ''
        -- JSON
        nvim_lsp.jsonls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.vscode-langservers-extracted}/bin/vscode-json-language-server', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "nim" lspLanguages) ''
        -- Nim
        nvim_lsp.nimls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.nim-language-server}/bin/nimlsp', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "nix" lspLanguages) ''
        -- Nix
        nvim_lsp.rnix.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.nix-language-server}/bin/rnix-lsp' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "python" lspLanguages) ''
        -- Python
        nvim_lsp.pyright.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.pyright}/bin/pyright-langserver', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "ruby" lspLanguages) ''
        -- Ruby
        nvim_lsp.solargraph.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.solargraph}/bin/solargraph', 'stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "rust" lspLanguages) ''
        -- Rust
        nvim_lsp.rust_analyzer.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.rust-analyzer}/bin/rust-analyzer' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "terraform" lspLanguages) ''
        -- Terraform
        nvim_lsp.terraformls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.terraform-language-server}/bin/terraform-ls', 'serve' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "typescript" lspLanguages) ''
        -- TypeScript
        nvim_lsp.tsserver.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.typescript-language-server}/bin/typescript-language-server', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "vim" lspLanguages) ''
        -- Vim
        nvim_lsp.vimls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.vim-language-server}/bin/vim-language-server', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem "yaml" lspLanguages) ''
        -- YAML
        nvim_lsp.yamlls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = { '${lsp.yaml-language-server}/bin/yaml-language-server', '--stdio' },
        }
      '')
      (pkgs.lib.optionalString (builtins.elem pkgs.system lsp.diagnostic-language-server.meta.platforms) ''
        -- Everything Else
        nvim_lsp.diagnosticls.setup {
          on_attach = on_attach,
          capabilities = capabilities,
          cmd = {"${lsp.diagnostic-language-server}/bin/diagnostic-languageserver", "--stdio"},
          filetypes = {
            "sh"
          },
          init_options = {
            linters = {'' + (pkgs.lib.optionalString (builtins.elem "bash" lspLanguages) ''
              shellcheck = {
                command = "${lsp.shellcheck}/bin/shellcheck",
                debounce = 100,
                args = {
                  "--format=json",
                  "-"
                },
                offsetLine = 0,
                offsetColumn = 0,
                sourceName = "shellcheck",
                formatLines = 1,
                parseJson = {
                  sourceName = "file",
                  -- sourceNameFilter = true,
                  line = "line",
                  column = "column",
                  endLine = "endLine",
                  endColumn = "endColumn",
                  message = "''${message} [SC''${code}]",
                  security = "level"
                },
                securities = {
                  error = "error",
                  warning = "warning",
                  note = "info",
                  style = "hint"
                }
              },'') + ''
            },
            filetypes = {'' + (pkgs.lib.optionalString (builtins.elem "bash" lspLanguages) ''
              sh = "shellcheck",'') + ''
            },
          }
        }
      '')
      (builtins.readFile ./configs/lspconfig-after.lua)
      "EOH"
    ]);
  }
]
