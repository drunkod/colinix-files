# gnome feeds RSS viewer
{ lib, sane-lib, ... }:

let
  feeds = import ./feeds.nix { inherit lib; };
in {
  sane.fs."/home/colin/.config/org.gabmus.gfeeds.json" =
  let
    myFeeds = feeds.texts ++ feeds.images;
  in sane-lib.fs.wantedText (builtins.toJSON {
    # feed format is a map from URL to a dict,
    #   with dict["tags"] a list of string tags.
    feeds = builtins.foldl' (acc: feed: acc // {
      "${feed.url}".tags = [ feed.cat feed.freq ];
    }) {} myFeeds;
    dark_reader = false;
    new_first = true;
    # windowsize = {
    #   width = 350;
    #   height = 650;
    # };
    max_article_age_days = 90;
    enable_js = false;
    max_refresh_threads = 3;
    # saved_items = {};
    # read_items = [];
    show_read_items = true;
    full_article_title = true;
    # views: "webview", "reader", "rsscont"
    default_view = "rsscont";
    open_links_externally = true;
    full_feed_name = false;
    refresh_on_startup = true;
    tags = lib.lists.unique (
      (builtins.catAttrs "cat" myFeeds) ++ (builtins.catAttrs "freq" myFeeds)
    );
    open_youtube_externally = false;
    media_player = "vlc";  # default: mpv
  });
}
