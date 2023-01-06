# news-flash RSS viewer
{ lib, sane-lib, ... }:

let
  feeds = import ./feeds.nix { inherit lib; };
in {
  sane.fs."/home/colin/.config/newsflashFeeds.opml" = sane-lib.fs.wantedText (
    feeds.feedsToOpml (feeds.texts ++ feeds.images)
  );
}
