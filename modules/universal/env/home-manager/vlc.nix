{ lib, ... }:
{
  home-manager.users.colin.xdg.configFile."vlc/vlcrc".text =
  let
    feeds = import ./feeds.nix { inherit lib; };
    podcastUrls = lib.strings.concatStringsSep "|" (
      builtins.map (feed: feed.url) feeds.podcasts
    );
  in ''
    [podcast]
    podcast-urls=${podcastUrls}
    [core]
    metadata-network-access=0
    [qt]
    qt-privacy-ask=0
  '';
}
