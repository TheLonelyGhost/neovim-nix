{ pkgs, lsp, ... }:

let
  nvim-lsp = import ./lsp {
    inherit pkgs lsp;
  };
  thelonelyghostDefaults = import ../config {
    inherit pkgs;
  };
in
[
  {
    plugin = pkgs.vimPlugins.editorconfig-vim;
  }
  {
    plugin = thelonelyghostDefaults;
  }
  {
    plugin = pkgs.vimPlugins.vim-gitgutter;
  }
  # Disabled because treesitter highlighting is faster/better for most syntaxes:
  # { plugin = pkgs.vimPlugins.vim-polyglot; }
  # Disabled because this oversteps treesitter vs. LSP functionality
  # {
  #   plugin = pkgs.vimPlugins.nvim-treesitter-refactor;
  # }
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
    plugin = pkgs.vimPlugins.nvim-treesitter.withPlugins (_: pkgs.tree-sitter.allGrammars);
    # buildInputs = [
    #   pkgs.tree-sitter
    #   pkgs.nodejs
    #   pkgs.gcc
    #   pkgs.git
    # ];
    config = ''
      lua <<EOH
      require'nvim-treesitter.configs'.setup {
        -- refactor = {
        --   highlight_definitions = { enable = true },
        --   smart_rename = {
        --     enable = true,
        --     keymaps = {
        --       smart_rename = "grr",
        --     },
        --   },
        --   navigation = {
        --     enable = false,
        --     keymaps = {
        --       goto_definition_lsp_fallback = "gnd",
        --       list_definitions = "gnD",
        --       list_definitions_toc = "gO",
        --       goto_next_usage = "<a-*>",
        --       goto_previous_usage = "<a-#>",
        --     },
        --   },
        -- },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
        indent = {
          enable = true,
        },
      }
      EOH

      set foldmethod=expr
      set foldexpr=nvim_treesitter#foldexpr()
      set foldlevelstart=5
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
      local cmp = require('cmp')

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
  nvim-lsp
]
