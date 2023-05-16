# gnome feeds RSS viewer
{ config, pkgs, sane-lib, ... }:

let
  feeds = sane-lib.feeds;
  all-feeds = config.sane.feeds;
  wanted-feeds = feeds.filterByFormat ["podcast"] all-feeds;
in {
  sane.programs.gpodder.package = pkgs.gpodder-configured;
  sane.programs.gpodder.fs.".config/gpodderFeeds.opml".symlink.text =
    feeds.feedsToOpml wanted-feeds
  ;
}
