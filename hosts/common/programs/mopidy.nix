{ config, lib, pkgs, ... }:
{
  sane.programs.mopidy = {
  };
  services.mopidy = lib.mkIf config.sane.programs.mopidy.enabled {
    enable = true;
    extensionPackages = with pkgs; [
      mopidy-jellyfin
      mopidy-mpd
      mopidy-mpris
      mopidy-spotify
      # TODO: mopidy-podcast, mopidy-youtube
    ];

    # config docs: <https://docs.mopidy.com/en/latest/config/>
    # query current config with: `sudo mopidyctl config`
    # configuration = "";
  };
}
