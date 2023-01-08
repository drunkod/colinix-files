{ ... }:
let
  hourly = { freq = "hourly"; };
  daily = { freq = "daily"; };
  weekly = { freq = "weekly"; };
  infrequent = { freq = "infrequent"; };

  art = { cat = "art"; };
  humor = { cat = "humor"; };
  pol = { cat = "pol"; };  # or maybe just "social"
  rat = { cat = "rat"; };
  tech = { cat = "tech"; };
  uncat = { cat = "uncat"; };

  mkRss = format: url: { inherit url format; } // uncat // infrequent;
  # format-specific helpers
  mkText = mkRss "text";
  mkImg = mkRss "image";
  mkPod = mkRss "podcast";

  # host-specific helpers
  mkSubstack = subdomain: { substack = subdomain; };

  podcasts = [
    (mkPod "https://lexfridman.com/feed/podcast/" // rat // weekly)
    ## Astral Codex Ten
    (mkPod "http://feeds.libsyn.com/108018/rss" // rat // daily)
    ## Econ Talk
    (mkPod "https://feeds.simplecast.com/wgl4xEgL" // rat // daily)
    ## Cory Doctorow
    (mkPod "https://feeds.feedburner.com/doctorow_podcast" // pol // infrequent)
    (mkPod "https://congressionaldish.libsyn.com/rss" // pol // infrequent)
    ## Civboot
    (mkPod "https://anchor.fm/s/34c7232c/podcast/rss" // tech // infrequent)
    (mkPod "https://feeds.feedburner.com/80000HoursPodcast" // rat // weekly)
    (mkPod "https://allinchamathjason.libsyn.com/rss" // pol // weekly)
    (mkPod "https://acquired.libsyn.com/rss" // tech // infrequent)
    (mkPod "https://rss.acast.com/deconstructed" // pol // infrequent)
    ## The Daily
    (mkPod "https://feeds.simplecast.com/54nAGcIl" // pol // daily)
    (mkPod "https://rss.acast.com/intercepted-with-jeremy-scahill" // pol // weekly)
    (mkPod "https://podcast.posttv.com/itunes/post-reports.xml" // pol // weekly)
    ## Eric Weinstein
    (mkPod "https://rss.art19.com/the-portal" // rat // infrequent)
    (mkPod "https://feeds.megaphone.fm/darknetdiaries" // tech // infrequent)
    (mkPod "http://feeds.wnyc.org/radiolab" // pol // infrequent)
    (mkPod "https://wakingup.libsyn.com/rss" // pol // infrequent)
    ## 99% Invisible
    (mkPod "https://feeds.simplecast.com/BqbsxVfO" // pol // infrequent)
    (mkPod "https://rss.acast.com/ft-tech-tonic" // tech // infrequent)
    (mkPod "https://feeds.feedburner.com/dancarlin/history?format=xml" // rat // infrequent)
    ## 60 minutes (NB: this features more than *just* audio?)
    (mkPod "https://www.cbsnews.com/latest/rss/60-minutes" // pol // infrequent)
    ## The Verge - Decoder
    (mkPod "https://feeds.megaphone.fm/recodedecode" // tech // weekly)
    ## Matrix (chat) Live
    (mkPod "https://feed.podbean.com/matrixlive/feed.xml" // tech // weekly)
    ## Michael Malice - Your Welcome
    (mkPod "https://www.podcastone.com/podcast?categoryID2=2232" // pol // weekly)
  ];

  texts = [
    # AGGREGATORS (> 1 post/day)
    (mkText "https://www.lesswrong.com/feed.xml" // rat // hourly)
    (mkText "http://www.econlib.org/index.xml" // pol // hourly)

    # AGGREGATORS (< 1 post/day)
    (mkText "https://palladiummag.com/feed" // uncat // weekly)
    (mkText "https://profectusmag.com/feed" // uncat // weekly)
    (mkText "https://semiaccurate.com/feed" // tech // weekly)
    (mkText "https://linuxphoneapps.org/blog/atom.xml" // tech // infrequent)
    (mkText "https://spectrum.ieee.org/rss" // tech // weekly)

    ## No Moods, Ads or Cutesy Fucking Icons
    (mkText "https://www.rifters.com/crawl/?feed=rss2" // uncat // weekly)

    # DEVELOPERS
    (mkText "https://uninsane.org/atom.xml" // infrequent // tech)
    (mkText "https://mg.lol/blog/rss/" // infrequent // tech)
    ## Ken Shirriff
    (mkText "https://www.righto.com/feeds/posts/default" // tech // infrequent)
    ## Vitalik Buterin
    (mkText "https://vitalik.ca/feed.xml" // tech // infrequent)
    ## ian (Sanctuary)
    (mkText "https://sagacioussuricata.com/feed.xml" // tech // infrequent)
    ## Bunnie Juang
    (mkText "https://www.bunniestudios.com/blog/?feed=rss2" // tech // infrequent)
    (mkText "https://blog.danieljanus.pl/atom.xml" // tech // infrequent)
    (mkText "https://ianthehenry.com/feed.xml" // tech // infrequent)
    (mkText "https://bitbashing.io/feed.xml" // tech // infrequent)
    (mkText "https://idiomdrottning.org/feed.xml" // uncat // daily)
    (mkText "https://anish.lakhwara.com/home.html" // tech // weekly)
    (mkText "https://www.jefftk.com/news.rss" // tech // daily)
    (mkText "https://pomeroyb.com/feed.xml" // tech // infrequent)

    # (TECH; POL) COMMENTATORS
    (mkSubstack "edwardsnowden" // pol // infrequent)
    (mkText "http://benjaminrosshoffman.com/feed" // pol // weekly)
    ## Ben Thompson
    (mkText "https://www.stratechery.com/rss" // pol // weekly)
    ## Balaji
    (mkText "https://balajis.com/rss" // pol // weekly)
    (mkText "https://www.ben-evans.com/benedictevans/rss.xml" // pol // weekly)
    (mkText "https://www.lynalden.com/feed" // pol // infrequent)
    (mkText "https://austinvernon.site/rss.xml" // tech // infrequent)
    (mkSubstack "oversharing" // pol // daily)
    (mkSubstack "doomberg" // tech // weekly)
    ## David Rosenthal
    (mkText "https://blog.dshr.org/rss.xml" // pol // weekly)
    ## Matt Levine
    (mkText "https://www.bloomberg.com/opinion/authors/ARbTQlRLRjE/matthew-s-levine.rss" // pol // weekly)
    (mkText "https://stpeter.im/atom.xml" // pol // weekly)

    # RATIONALITY/PHILOSOPHY/ETC
    (mkSubstack "samkriss" // humor // infrequent)
    (mkText "https://unintendedconsequenc.es/feed" // rat // infrequent)
    (mkText "https://applieddivinitystudies.com/atom.xml" // rat // weekly)
    (mkText "https://slimemoldtimemold.com/feed.xml" // rat // weekly)
    (mkText "https://www.richardcarrier.info/feed" // rat // weekly)
    (mkText "https://www.gwern.net/feed.xml" // uncat // infrequent)
    ## Jason Crawford
    (mkText "https://rootsofprogress.org/feed.xml" // rat // weekly)
    ## Robin Hanson
    (mkText "https://www.overcomingbias.com/feed" // rat // daily)
    ## Scott Alexander
    (mkSubstack "astralcodexten" // rat // daily)
    ## Paul Christiano
    (mkText "https://sideways-view.com/feed" // rat // infrequent)
    ## Sean Carroll
    (mkText "https://www.preposterousuniverse.com/rss" // rat // infrequent)

    ## mostly dating topics. not advice, or humor, but looking through a social lens
    (mkText "https://putanumonit.com/feed" // rat // infrequent)

    # CODE
    # (mkText "https://github.com/Kaiteki-Fedi/Kaiteki/commits/master.atom" // tech // infrequent)
  ];

  images = [
    (mkImg "https://www.smbc-comics.com/comic/rss" // humor // daily)
    (mkImg "https://xkcd.com/atom.xml" // humor // daily)
    (mkImg "https://pbfcomics.com/feed" // humor // infrequent)
    # (mkImg "http://dilbert.com/feed" // humor // daily)

    # ART
    (mkImg "https://miniature-calendar.com/feed" // art // daily)
  ];
in
{
  sane.feeds = texts ++ images ++ podcasts;
}
