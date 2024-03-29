{ pkgs, lsp, ... }:

let
  diagnostic = import ./diagnostic.nix { inherit pkgs lsp; };
  allTools = {
    bash = rec {
      package = lsp.bash-language-server;
      cmd = [ "bash-language-server" "start" ];
      nvimLspAttribute = "bashls";
      settings = { };
    };
    # crystal = rec {
    #   package = lsp.scry;
    #   cmd = [ "scry" ];
    #   nvimLspAttribute = "scry";
    #   settings = { };
    # };
    css = rec {
      package = lsp.stylelint-lsp;
      cmd = [ "stylelint-lsp" "--stdio" ];
      nvimLspAttribute = "stylelint_lsp";
      settings = { };
    };
    graphviz = rec {
      package = lsp.dot-language-server;
      cmd = [ "dot-language-server" "--stdio" ];
      nvimLspAttribute = "dotls";
      settings = { };
    };
    docker = rec {
      package = lsp.dockerfile-language-server;
      cmd = [ "docker-langserver" "--stdio" ];
      nvimLspAttribute = "dockerls";
      settings = { };
    };
    go = rec {
      package = lsp.gopls;
      cmd = [ "gopls" ];
      nvimLspAttribute = "gopls";
      settings = {
        gopls = {
          experimentalPostfixCompletions = true;
          analyses = {
            unusedparams = true;
            shadow = true;
          };
          staticcheck = true;
        };
      };
    };
    html = rec {
      package = lsp.vscode-langservers-extracted;
      cmd = [ "vscode-html-language-server" "--stdio" ];
      nvimLspAttribute = "html";
      settings = { };
    };
    json = rec {
      package = lsp.vscode-langservers-extracted;
      cmd = [ "vscode-json-language-server" "--stdio" ];
      nvimLspAttribute = "jsonls";
      settings = { };
    };
    nim = rec {
      package = lsp.nim-language-server;
      cmd = [ "nimlsp" "--stdio" ];
      nvimLspAttribute = "nimls";
      settings = { };
    };
    nix = rec {
      package = lsp.nix-language-server;
      cmd = [ "rnix-lsp" ];
      nvimLspAttribute = "rnix";
      settings = { };
    };
    python = rec {
      package = lsp.pyright;
      cmd = [ "pyright-langserver" "--stdio" ];
      nvimLspAttribute = "pyright";
      settings = { };
    };
    ruby = rec {
      package = lsp.solargraph;
      cmd = [ "solargraph" "stdio" ];
      nvimLspAttribute = "solargraph";
      settings = { };
    };
    rust = rec {
      package = lsp.rust-analyzer;
      cmd = [ "rust-analyzer" ];
      nvimLspAttribute = "rust_analyzer";
      settings = { };
    };
    terraform = rec {
      package = lsp.terraform-language-server;
      cmd = [ "terraform-ls" "serve" ];
      nvimLspAttribute = "terraformls";
      settings = { };
    };
    typescript = rec {
      package = lsp.typescript-language-server;
      cmd = [ "typescript-language-server" "--stdio" ];
      nvimLspAttribute = "tsserver";
      settings = { };
    };
    vim = rec {
      package = lsp.vim-language-server;
      cmd = [ "vim-language-server" "--stdio" ];
      nvimLspAttribute = "vimls";
      settings = { };
    };
    yaml = rec {
      package = lsp.yaml-language-server;
      cmd = [ "yaml-language-server" "--stdio" ];
      nvimLspAttribute = "yamlls";
      settings = { };
    };
  };

  utils = import ./utils.nix { inherit pkgs; };
  tools = utils.filterSupportedTools allTools;

  configFor = lang:
    let
      inherit (tools.${lang}) cmd nvimLspAttribute settings;

      config = {
        inherit cmd settings;
      };
    in
    ''
      -- Language: ${lang}
      lspconfig['${nvimLspAttribute}'].setup(${utils.toLua config})
    '';

in
{
  inherit tools;

  buildInputs = (utils.collectBuildInputs tools) ++ diagnostic.buildInputs;

  # Lua configuration of the nvim-lspconfig plugin
  config =
    let
      preamble = builtins.readFile ./preamble.lua;
      individualConfigs = builtins.map configFor (builtins.attrNames tools);
    in
    builtins.concatStringsSep "\n" (
      [preamble]
      ++
      individualConfigs
      ++
      [diagnostic.config]
    );
}
