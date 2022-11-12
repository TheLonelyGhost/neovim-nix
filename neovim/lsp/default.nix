{ pkgs, lsp, ... }:

let
  lspTools = import ./language-servers.nix {
    inherit pkgs lsp;
  };
in
{
  plugin = pkgs.vimPlugins.nvim-lspconfig;
  config = (builtins.concatStringsSep "\n\n" [
    "lua <<EOH"
    lspTools.config
    "EOH"
  ]);
}
