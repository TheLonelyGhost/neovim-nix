{ pkgs, ... }:

pkgs.vimUtils.buildVimPlugin {
  pname = "tlg-defaults";
  version = "2022-11-12";
  src = ./thelonelyghost-defaults;
  meta = {
    description = "TheLonelyGhost's default set of preferred vim settings, including filetype-dependent ones";
    homepage = "https://www.thelonelyghost.com/";
    license = pkgs.lib.licenses.mit;
  };
}
