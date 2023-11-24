{ pkgs, ... }:

let
  version = "0.2.6";
in
pkgs.vimUtils.buildVimPlugin {
  pname = "catppuccin-nvim";
  inherit version;

  src = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo = "nvim";
    rev = "v${version}";
    sha256 = "sha256-vhKhEXCkmz0KH8LlZzcOvGkvdwp7TtI7ZV7ZxojgnAI="; # pkgs.lib.fakeSha256;
  };

  meta = {
    description = "(Neovim plugin) Soothing pastel theme for the high-spirited!";
    homepage = "https://catppuccin.com/";
    license = pkgs.lib.licenses.mit;
  };
}
