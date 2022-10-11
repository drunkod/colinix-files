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
      type = types.attrs;
      default = {
        # AGGREGATORS (> 1 post/day)
        "https://www.lesswrong.com/feed.xml" = {
          cat = "rat";
          freq = "hourly";
        };
        "http://www.econlib.org/index.xml" = {
          cat = "pol";
          freq = "hourly";
        };
        # AGGREGATORS (< 1 post/day)
        "https://palladiummag.com/feed" = {
          cat = "uncat";
          freq = "weekly";
        };
        "https://profectusmag.com/feed" = {
          cat = "uncat";
          freq = "weekly";
        };

        "https://semiaccurate.com/feed" = {
          cat = "tech";
          freq = "weekly";
        };
        "https://linuxphoneapps.org/blog/atom.xml" = {
          cat = "tech";
          freq = "infrequently";
        };
        "https://spectrum.ieee.org/rss" = {
          cat = "tech";
          freq = "weekly";
        };

        ## No Moods, Ads or Cutesy Fucking Icons
        "https://www.rifters.com/crawl/?feed=rss2" = {
          cat = "uncat";
          freq = "weekly";
        };

        # DEVELOPERS
        "https://mg.lol/blog/rss/" = {
          cat = "infrequent";
          freq = "tech";
        };
        ## Ken Shirriff
        "https://www.righto.com/feeds/posts/default" = {
          cat = "tech";
          freq = "infrequent";
        };

        ## Vitalik Buterin
        "https://vitalik.ca/feed.xml" = {
          cat = "tech";
          freq = "infrequent";
        };
        ## ian (Sanctuary)
        "https://sagacioussuricata.com/feed.xml" = {
          cat = "tech";
          freq = "infrequent";
        };
        ## Bunnie Juang
        "https://www.bunniestudios.com/blog/?feed=rss2" = {
          cat = "tech";
          freq = "infrequent";
        };
        "https://blog.danieljanus.pl/atom.xml" = {
          cat = "tech";
          freq = "infrequent";
        };
        "https://ianthehenry.com/feed.xml" = {
          cat = "tech";
          freq = "infrequent";
        };
        "https://bitbashing.io/feed.xml" = {
          cat = "tech";
          freq = "infrequent";
        };
        "https://idiomdrottning.org/feed.xml" = {
          cat = "uncat";
          freq = "daily";
        };

        # (TECH; POL) COMMENTATORS
        "http://benjaminrosshoffman.com/feed" = {
          cat = "pol";
          freq = "weekly";
        };
        ## Ben Thompson
        "https://www.stratechery.com/rss" = {
          cat = "pol";
          freq = "weekly";
        };
        ## Balaji
        "https://balajis.com/rss" = {
          cat = "pol";
          freq = "weekly";
        };
        "https://www.ben-evans.com/benedictevans/rss.xml" = {
          cat = "pol";
          freq = "weekly";
        };
        "https://www.lynalden.com/feed" = {
          cat = "pol";
          freq = "infrequent";
        };
        "https://austinvernon.site/rss.xml" = {
          cat = "tech";
          freq = "infrequent";
        };
        "https://oversharing.substack.com/feed" = {
          cat = "pol";
          freq = "daily";
        };
        "https://doomberg.substack.com/feed" = {
          cat = "tech";
          freq = "weekly";
        };
        ## David Rosenthal
        "https://blog.dshr.org/rss.xml" = {
          cat = "pol";
          freq = "weekly";
        };
        ## Matt Levine
        "https://www.bloomberg.com/opinion/authors/ARbTQlRLRjE/matthew-s-levine.rss" = {
          cat = "pol";
          freq = "weekly";
        };

        # RATIONALITY/PHILOSOPHY/ETC
        "https://samkriss.substack.com/feed" = {
          cat = "uncat";
          freq = "infrequent";
        };
           # ... satire? phil?
        "https://unintendedconsequenc.es/feed" = {
          cat = "rat";
          freq = "infrequent";
        };

        "https://applieddivinitystudies.com/atom.xml" = {
          cat = "rat";
          freq = "weekly";
        };
        "https://slimemoldtimemold.com/feed.xml" = {
          cat = "rat";
          freq = "weekly";
        };

        "https://www.richardcarrier.info/feed" = {
          cat = "rat";
          freq = "weekly";
        };
        "https://www.gwern.net/feed.xml" = {
          cat = "uncat";
          freq = "infrequent";
        };

        ## Jason Crawford
        "https://rootsofprogress.org/feed.xml" = {
          cat = "rat";
          freq = "weekly";
        };
        ## Robin Hanson
        "https://www.overcomingbias.com/feed" = {
          cat = "rat";
          freq = "daily";
        };
        ## Scott Alexander
        "https://astralcodexten.substack.com/feed.xml" = {
          cat = "rat";
          freq = "daily";
        };
        ## Paul Christiano
        "https://sideways-view.com/feed" = {
          cat = "rat";
          freq = "infrequent";
        };
        ## Sean Carroll
        "https://www.preposterousuniverse.com/rss" = {
          cat = "rat";
          freq = "infrequent";
        };

        # COMICS
        "https://www.smbc-comics.com/comic/rss" = {
          cat = "visual";
          freq = "daily";
        };
        "https://xkcd.com/atom.xml" = {
          cat = "visual";
          freq = "daily";
        };
        "http://dilbert.com/feed" = {
          freq = "daily";
          cat = "visual";
        };

        # ART
        "https://miniature-calendar.com/feed" = {
          cat = "visual";
          freq = "daily";
        };

        # CODE
        "https://github.com/Kaiteki-Fedi/Kaiteki/commits/master.atom" = {
          cat = "tech";
          freq = "infrequent";
        };
      };
    };
  };
}
