{ config, lib, pkgs, ... }:
{
  fonts = lib.mkIf config.sane.programs.fontconfig.enabled {
    fontconfig.enable = true;
    fontconfig.defaultFonts = lib.mkDefault {
      emoji = [ "Font Awesome 6 Free" "Noto Color Emoji" ];
      monospace = [ "Hack" ];
      serif = [ "DejaVu Serif" ];
      sansSerif = [ "DejaVu Sans" ];
    };
    enableDefaultFonts = lib.mkDefault true;
    fonts = with pkgs; lib.mkDefault [ font-awesome noto-fonts-emoji hack-font ];
  };
}
