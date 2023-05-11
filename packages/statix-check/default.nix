{ pkgs, lsp, ... }:

pkgs.writeShellApplication {
  name = "statix-check";

  runtimeInputs = [
    lsp.statix
  ];

  text = ''
    statix check "$@" && printf '{"report": []}\n'
  '';
}
