# news-flash RSS viewer
{ config, sane-lib, ... }:

let
  feeds = sane-lib.feeds;
  all-feeds = config.sane.feeds;
  wanted-feeds = feeds.filterByFormat ["text" "image"] all-feeds;
in {
  sane.user.fs.".config/newsflashFeeds.opml" = sane-lib.fs.wantedText (
    feeds.feedsToOpml wanted-feeds
  );
}
