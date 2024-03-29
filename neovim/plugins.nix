{ pkgs, lsp, ... }:

let
  nvim-lsp = import ./lsp {
    inherit pkgs lsp;
  };
  thelonelyghostDefaults = import ../config { inherit pkgs; };
  catppuccin = import ../packages/nvim-catppuccin { inherit pkgs; };
in
[
  { plugin = pkgs.vimPlugins.editorconfig-vim; }
  { plugin = thelonelyghostDefaults; }
  {
    plugin = pkgs.vimPlugins.lsp-colors-nvim;
    config = ''
      lua <<EOH
      require('lsp-colors').setup {
        Error = "#db4b4b",
        Warning = "#e0af68",
        Information = "#0db9d7",
        Hint = "#10B981",
      }
      EOH
    '';
  }
  {
    plugin = pkgs.vimPlugins.gitsigns-nvim;
    config = ''
      lua <<EOH
      require('gitsigns').setup {
        -- numhl = true,
        current_line_blame = true,
        current_line_blame_opts = {
          -- virt_text_pos = 'right_align',
          ignore_whitespace = true,
        },
        yadm = {
          enable = false,
        },
      }
      EOH
    '';
  }
  {
    plugin = pkgs.vimPlugins.telescope-nvim;
    buildInputs = [
      pkgs.ripgrep
      pkgs.fd
    ];
    config = ''
      lua <<EOH
      require('telescope').setup {
      }
      EOH
    '';
  }

  # Replaced with tree-sitter. Highlighting is faster/better for most syntaxes:
  # { plugin = pkgs.vimPlugins.vim-polyglot; }

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
  { plugin = pkgs.vimPlugins.nvim-treesitter-pyfold; }
  { plugin = pkgs.vimPlugins.nvim-ts-rainbow; }
  { plugin = pkgs.vimPlugins.nvim-treesitter-textobjects; }
  {
    plugin = pkgs.vimPlugins.nvim-treesitter.withAllGrammars;
    buildInputs = [
      pkgs.tree-sitter
      pkgs.nodejs
      pkgs.gcc
    ];
    config = ''
      lua <<EOH
      require'nvim-treesitter.configs'.setup {
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
        indent = {
          enable = true,
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
          },
          lsp_interop = {
            enable = true,
            border = 'none',
          },
        },
        pyfold = {
          enable = true,
          custom_foldtext = true, -- sets provided foldtext on window where module is active
        },
        rainbow = {
          enable = true,
          extended_mode = true,
          max_file_lines = 100000,
        },
      }
      EOH
      set foldmethod=expr
      set foldexpr=nvim_treesitter#foldexpr()
      set nofoldenable
      set foldlevelstart=5
    '';
  }

  { plugin = pkgs.vimPlugins.vim-vsnip; }
  { plugin = pkgs.vimPlugins.vim-vsnip-integ; }
  { plugin = pkgs.vimPlugins.cmp-buffer; }
  { plugin = pkgs.vimPlugins.cmp-cmdline; }
  { plugin = pkgs.vimPlugins.cmp-path; }
  { plugin = pkgs.vimPlugins.cmp-nvim-lsp; }
  { plugin = pkgs.vimPlugins.lspkind-nvim; }
  {
    plugin = pkgs.vimPlugins.nvim-cmp;
    config = ''
      " Handy stuff to display autocompletion, but not autoinsert
      set completeopt=menuone,noinsert,noselect

      " Skip entries related to insert completion menu events in `:messages`
      set shortmess+=c

      lua <<EOH
      local cmp = require('cmp')
      local lspkind = require('lspkind')

      cmp.setup({
        snippet = {
          expand = function(args)
            vim.fn["vsnip#anonymous"](args.body)
          end,
        },
        mappings = {
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
        },
        formatting = {
          format = lspkind.cmp_format({
            mode = 'symbol_text',
            max_width = 50,
          }),
        },
        sources = {
          { name = 'nvim_lsp' },
          { name = 'vsnip' },
          { name = 'buffer' },
        },
      })
      EOH
    '';
  }

  # {
  #   plugin = catppuccin;
  #   config = ''
  #   colorscheme catppuccin-mocha
  #   '';
  # }
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
