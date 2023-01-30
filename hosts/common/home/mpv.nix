{ sane-lib, ... }:

{
  # format is <key>=%<length>%<value>
  sane.user.fs.".config/mpv/mpv.conf" = sane-lib.fs.wantedText ''
    save-position-on-quit=%3%yes
    keep-open=%3%yes
  '';
}

