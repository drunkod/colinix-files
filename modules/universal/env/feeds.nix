{ lib, ... }:

with lib;
{
  options = {
    # TODO: fold this into RSS, with an `audio` category
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
        "https://acquired.libsyn.com/rss"
        "https://rss.acast.com/deconstructed"
        ## The Daily
        "https://feeds.simplecast.com/54nAGcIl"
        "https://rss.acast.com/intercepted-with-jeremy-scahill"
        "https://podcast.posttv.com/itunes/post-reports.xml"
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

    sane.feeds.rss = mkOption {
      # the format here is just what's native to gfeeds
      type = types.attrs;
      default = {
        # AGGREGATORS (> 1 post/day)
        "https://www.lesswrong.com/feed.xml" = { tags = [ "hourly" "rat" ]; };
        "http://www.econlib.org/index.xml" = { tags = [ "hourly" "pol" ]; };
        # AGGREGATORS (< 1 post/day)
        "https://palladiummag.com/feed" = { tags = [ "weekly" "uncat" ]; };
        "https://profectusmag.com/feed" = { tags = [ "weekly" "uncat" ]; };

        "https://semiaccurate.com/feed" = { tags = [ "weekly" "tech" ]; };
        "https://linuxphoneapps.org/blog/atom.xml" = { tags = [ "infrequent" "tech" ]; };
        "https://spectrum.ieee.org/rss" = { tags = [ "weekly" "tech" ]; };

        ## No Moods, Ads or Cutesy Fucking Icons
        "https://www.rifters.com/crawl/?feed=rss2" = { tags = [ "weekly" "uncat" ]; };

        # DEVELOPERS
        "https://mg.lol/blog/rss/" = { tags = [ "infrequent" "tech" ]; };
        ## Ken Shirriff
        "https://www.righto.com/feeds/posts/default" = { tags = [ "infrequent" "tech" ]; };
        ## Vitalik Buterin
        "https://vitalik.ca/feed.xml" = { tags = [ "infrequent" "tech" ]; };
        ## ian (Sanctuary)
        "https://sagacioussuricata.com/feed.xml" = { tags = [ "infrequent" "tech" ]; };
        ## Bunnie Juang
        "https://www.bunniestudios.com/blog/?feed=rss2" = { tags = [ "infrequent" "tech" ]; };
        "https://blog.danieljanus.pl/atom.xml" = { tags = [ "infrequent" "tech" ]; };
        "https://ianthehenry.com/feed.xml" = { tags = [ "infrequent" "tech" ]; };
        "https://bitbashing.io/feed.xml" = { tags = [ "infrequent" "tech" ]; };
        "https://idiomdrottning.org/feed.xml" = { tags = [ "daily" "uncat" ]; };

        # (TECH; POL) COMMENTATORS
        "http://benjaminrosshoffman.com/feed" = { tags = [ "weekly" "pol" ]; };
        ## Ben Thompson
        "https://www.stratechery.com/rss" = { tags = [ "weekly" "pol" ]; };
        ## Balaji
        "https://balajis.com/rss" = { tags = [ "weekly" "pol" ]; };
        "https://www.ben-evans.com/benedictevans/rss.xml" = { tags = [ "weekly" "pol" ]; };
        "https://www.lynalden.com/feed" = { tags = [ "infrequent" "pol" ]; };
        "https://austinvernon.site/rss.xml" = { tags = [ "infrequent" "tech" ]; };
        "https://oversharing.substack.com/feed" = { tags = [ "daily" "pol" ]; };
        "https://doomberg.substack.com/feed" = { tags = [ "weekly" "tech" ]; };
        ## David Rosenthal
        "https://blog.dshr.org/rss.xml" = { tags = [ "weekly" "pol" ]; };
        ## Matt Levine
        "https://www.bloomberg.com/opinion/authors/ARbTQlRLRjE/matthew-s-levine.rss" = { tags = [ "weekly" "pol" ]; };

        # RATIONALITY/PHILOSOPHY/ETC
        "https://samkriss.substack.com/feed" = { tags = [ "infrequent" "uncat" ]; };  # ... satire? phil?
        "https://unintendedconsequenc.es/feed" = { tags = [ "infrequent" "rat" ]; };

        "https://applieddivinitystudies.com/atom.xml" = { tags = [ "weekly" "rat" ]; };
        "https://slimemoldtimemold.com/feed.xml" = { tags = [ "weekly" "rat" ]; };

        "https://www.richardcarrier.info/feed" = { tags = [ "weekly" "rat" ]; };
        "https://www.gwern.net/feed.xml" = { tags = [ "infrequent" "uncat" ]; };

        ## Jason Crawford
        "https://rootsofprogress.org/feed.xml" = { tags = [ "weekly" "rat" ]; };
        ## Robin Hanson
        "https://www.overcomingbias.com/feed" = { tags = [ "daily" "rat" ]; };
        ## Scott Alexander
        "https://astralcodexten.substack.com/feed.xml" = { tags = [ "daily" "rat" ]; };
        ## Paul Christiano
        "https://sideways-view.com/feed" = { tags = [ "infrequent" "rat" ]; };
        ## Sean Carroll
        "https://www.preposterousuniverse.com/rss" = { tags = [ "infrequent" "rat" ]; };

        # COMICS
        "https://www.smbc-comics.com/comic/rss" = { tags = [ "daily" "visual" ]; };
        "https://xkcd.com/atom.xml" = { tags = [ "daily" "visual" ]; };
        "http://dilbert.com/feed" = { tags = ["daily" "visual" ]; };

        # ART
        "https://miniature-calendar.com/feed" = { tags = [ "daily" "visual" ]; };

        # CODE
        "https://github.com/Kaiteki-Fedi/Kaiteki/commits/master.atom" = { tags = [ "infrequent" "tech" ]; };
      };
    };
  };
}
