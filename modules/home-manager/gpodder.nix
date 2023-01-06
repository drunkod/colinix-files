# gnome feeds RSS viewer
{ lib, sane-lib, ... }:

let
  feeds = import ./feeds.nix { inherit lib; };
in {
  sane.fs."/home/colin/.config/gpodderFeeds.opml" = sane-lib.fs.wantedText (
    feeds.feedsToOpml feeds.podcasts
  );
}
