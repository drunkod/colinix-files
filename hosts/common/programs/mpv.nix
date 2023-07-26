# mpv docs:
# - <https://mpv.io/manual/master>
# - <https://github.com/mpv-player/mpv/wiki>
# curated mpv mods/scripts/users:
# - <https://github.com/stax76/awesome-mpv>
{ ... }:

{
  sane.programs.mpv = {
    persist.plaintext = [ ".config/mpv/watch_later" ];
    # format is <key>=%<length>%<value>
    fs.".config/mpv/mpv.conf".symlink.text = ''
      save-position-on-quit=%3%yes
      keep-open=%3%yes
    '';
    fs.".config/mpv/script-opts/osc.conf".symlink.text = ''
      # make the on-screen controls *always* visible
      # unfortunately, this applies to full-screen as well
      # - docs: <https://mpv.io/manual/master/#on-screen-controller-visibility>
      visibility=always
    '';

    mime.priority = 200;  # default = 100; 200 means to yield to other apps
    mime.associations."audio/flac" = "mpv.desktop";
    mime.associations."audio/mpeg" = "mpv.desktop";
    mime.associations."audio/x-vorbis+ogg" = "mpv.desktop";
    mime.associations."video/mp4" = "mpv.desktop";
    mime.associations."video/quicktime" = "mpv.desktop";
    mime.associations."video/webm" = "mpv.desktop";
    mime.associations."video/x-matroska" = "mpv.desktop";
  };
}

