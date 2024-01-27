# TROUBLESHOOTING:
# - turn the tv off and on again (no, really...)
#
# SANITY CHECKS:
# - `go2tv -u 'https://uninsane.org/share/AmenBreak.mp4'`
#   - LGTV: works, but not seekable
# - `go2tv -u 'https://youtu.be/p3G5IXn0K7A'`
#   - LGTV: FAILS ("this file cannot be recognized")
#     - no fix via transcoding, altering the URI, etc.
#     - workable if you use an invidious frontend, but you lose seeking.
#       - e.g. `go2tv -u 'https://inv.us.projectsegfau.lt/latest_version?id=qBzjHU_zEwM&itag=18'`
#       - e.g. `go2tv -tc -u 'https://yt.artemislena.eu/latest_version?id=qBzjHU_zEwM&itag=22'`
#       - sometimes transcoding is needed, sometimes not...
# - `go2tv -v /mnt/servo-media/Videos/Shows/bebop/session1.mkv`
#   - LGTV: works
# - `go2tv -tc -v /mnt/servo-media/Videos/Shows/bebop/session1.mkv`
#   - LGTV: works
#
# WHEN TO TRANSCODE:
# - mkv container + mpeg-2 video + AC-3/48k stereo audio:
#   - LGTV: no transcoding needed
# - mkv container + H.264 video + AAC/48k 5.1 audio:
#   - LGTV: no transcoding needed
# - mp4 container + H.264 video + MP3/48k stereo audio:
#   - LGTV: no transcoding needed
# - mp4 container + H.264 video + AAC/44k1 stereo audio:
#   - LGTV: no transcoding needed
# - mkv container + H.265 video + E-AC-3/48k stereo audio:
#   - LGTV: no transcoding needed
{ config, lib, pkgs, ... }:
let
  cfg = config.sane.programs.go2tv;
in
{
  sane.programs.go2tv = {
    sandbox.method = "bwrap";
    sandbox.extraConfig = [
      "--sane-sandbox-autodetect"
    ];
    # for GUI invocation, allow the common media directories
    sandbox.extraHomePaths = [
      "Music"
      "Videos"
    ];
    sandbox.extraPaths = [
      "/mnt/servo-media/Music"
      "/mnt/servo-media/Videos"
    ];
  };
  # for serving local files
  # see: go2tv/soapcalls/utils/iptools.go
  # go2tv tries port 3500, and then walks up from there port-by-port until it finds a free one.
  # it tries 1000 ports, but hopefully we won't need so many.
  networking.firewall.allowedTCPPorts = lib.mkIf cfg.enabled (lib.range 3500 3519);
}
