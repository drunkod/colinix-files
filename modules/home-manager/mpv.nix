{ config, lib, sane-lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  # format is <key>=%<length>%<value>
  sane.fs."/home/colin/.config/mpv/mpv.conf" = sane-lib.fs.wantedText ''
    save-position-on-quit=%3%yes
    keep-open=%3%yes
  '';
}

