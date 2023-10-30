{ pkgs, ... }:
{
  sane.programs.flare-signal = {
    package = pkgs.flare-signal-nixified;
    persist.private = [
      # everything: conf, state, files, all opaque
      ".local/share/flare"
    ];
  };
}
