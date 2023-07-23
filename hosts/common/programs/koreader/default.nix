{ config, lib, pkgs, sane-lib, ... }:

let
  feeds = sane-lib.feeds;
  allFeeds = config.sane.feeds;
  wantedFeeds = feeds.filterByFormat [ "image" "text" ] allFeeds;
  koreaderRssEntries = builtins.map (feed:
    # format:
    # { "<rss/atom url>", limit = <int>, download_full_article=<bool>, include_images=<bool>, enable_filter=<bool>, filter_element = "<css selector>"},
    # limit = 0                    => download and keep *all* articles
    # download_full_article = true => populate feed by downloading the webpage -- not just what's encoded in the RSS <article> tags
    # - use this for articles where the RSS only encodes content previews
    # - in practice, most articles don't work with download_full_article = false
    # enable_filter         = true => only render content that matches the filter_element css selector.
    let fields = [
      (lib.escapeShellArg feed.url)
      "limit = 5"
      "download_full_article = true"
      "include_images = true"
      "enable_filter = false"
      "filter_element = \"\""
    ]; in "{ ${lib.concatStringsSep ", " fields } }"
  ) wantedFeeds;
in {
  sane.programs.koreader = {
    package = pkgs.koreader-from-src;
    # koreader applies these lua "patches" at boot:
    # - <https://github.com/koreader/koreader/wiki/User-patches>
    # - TODO: upstream this patch to koreader
    # fs.".config/koreader/patches".symlink.target = "${./.}";
    fs.".config/koreader/patches/2-colin-NetworkManager-isConnected.lua".symlink.target = "${./2-colin-NetworkManager-isConnected.lua}";

    # koreader news plugin, enabled by default. file format described here:
    # - <repo:koreader/koreader:plugins/newsdownloader.koplugin/feed_config.lua>
    fs.".config/koreader/news/feed_config.lua".symlink.text = ''
      return {--do NOT change this line
        ${lib.concatStringsSep ",\n  " koreaderRssEntries}
      }--do NOT change this line
    '';

    # koreader on aarch64 errors if there's no fonts directory (sandboxing thing, i guess)
    fs.".local/share/fonts".dir = {};

    # history, cache, dictionaries...
    # could be more explicit if i symlinked the history.lua file to somewhere it can persist better.
    persist.plaintext = [ ".config/koreader" ];
  };
}
