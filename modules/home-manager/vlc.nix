{ config, lib, sane-lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  sane.fs."/home/colin/.config/vlc/vlcrc" =
  let
    feeds = import ./feeds.nix { inherit lib; };
    podcastUrls = lib.strings.concatStringsSep "|" (
      builtins.map (feed: feed.url) feeds.podcasts
    );
  in sane-lib.fs.wantedText ''
    [podcast]
    podcast-urls=${podcastUrls}
    [core]
    metadata-network-access=0
    [qt]
    qt-privacy-ask=0
  '';
}
