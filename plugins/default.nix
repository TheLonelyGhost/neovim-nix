{ pkgs, ... }:

{
  thelonelyghost-defaults = pkgs.vimUtils.buildVimPluginFrom2Nix {
    pname = "tlg-defaults";
    version = "2020-05-30";
    src = ./thelonelyghost-defaults;
    meta = {
      description = "TheLonelyGhost's default set of preferred vim settings, including filetype-dependent ones";
      homepage = "https://www.thelonelyghost.com/";
      license = pkgs.lib.licenses.mit;
    };
  };
}
