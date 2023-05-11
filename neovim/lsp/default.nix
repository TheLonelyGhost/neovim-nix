{ pkgs, lsp, ... }:

let
  lspTools = import ./language-servers.nix {
    inherit pkgs lsp;
  };
in
{
  plugin = pkgs.vimPlugins.nvim-lspconfig;
  inherit (lspTools) buildInputs;
  config = builtins.concatStringsSep "\n\n" [
    "lua <<EOH"
    lspTools.config
    "EOH"
  ];
}
