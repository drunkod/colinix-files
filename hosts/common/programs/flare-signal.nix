{ ... }:
{
  sane.programs.flare-signal = {
    persist.private = [
      # everything: conf, state, files, all opaque
      ".local/share/flare"
    ];
  };
}
