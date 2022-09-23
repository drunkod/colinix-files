{ lib, ... }:

with lib;
{
  options = {
    sane.feeds.podcastUrls = mkOption {
      type = types.listOf types.str;
      default = [
        "https://lexfridman.com/feed/podcast/"
        ## Astral Codex Ten
        "http://feeds.libsyn.com/108018/rss"
        ## Econ Talk
        "https://feeds.simplecast.com/wgl4xEgL"
        ## Cory Doctorow
        "https://feeds.feedburner.com/doctorow_podcast"
        "https://congressionaldish.libsyn.com/rss"
        ## Civboot
        "https://anchor.fm/s/34c7232c/podcast/rss"
        "https://feeds.feedburner.com/80000HoursPodcast"
        "https://allinchamathjason.libsyn.com/rss"
        ## Eric Weinstein
        "https://rss.art19.com/the-portal"
        "https://feeds.megaphone.fm/darknetdiaries"
        "http://feeds.wnyc.org/radiolab"
        "https://wakingup.libsyn.com/rss"
        ## 99% Invisible
        "https://feeds.simplecast.com/BqbsxVfO"
        "https://rss.acast.com/ft-tech-tonic"
        "https://feeds.feedburner.com/dancarlin/history?format=xml"
        ## 60 minutes (NB: this features more than *just* audio?)
        "https://www.cbsnews.com/latest/rss/60-minutes"
      ];
    };
  };
}
