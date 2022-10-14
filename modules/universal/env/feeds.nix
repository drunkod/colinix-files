{ lib }:

rec {
  # TODO: fold this into RSS, with an `audio` category
  podcastUrls = [
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

  rss =
  let
    hourly = { freq = "hourly"; };
    daily = { freq = "daily"; };
    weekly = { freq = "weekly"; };
    infrequent = { freq = "infrequent"; };
    rat = { cat = "rat"; };
    tech = { cat = "tech"; };
    pol = { cat = "pol"; };
    uncat = { cat = "uncat"; };
    visual = { cat = "visual"; };
  in {
    # AGGREGATORS (> 1 post/day)
    "https://www.lesswrong.com/feed.xml" = rat // hourly;
    "http://www.econlib.org/index.xml" = pol // hourly;

    # AGGREGATORS (< 1 post/day)
    "https://palladiummag.com/feed" = uncat // weekly;
    "https://profectusmag.com/feed" = uncat // weekly;
    "https://semiaccurate.com/feed" = tech // weekly;
    "https://linuxphoneapps.org/blog/atom.xml" = tech // infrequent;
    "https://spectrum.ieee.org/rss" = tech // weekly;

    ## No Moods, Ads or Cutesy Fucking Icons
    "https://www.rifters.com/crawl/?feed=rss2" = uncat // weekly;

    # DEVELOPERS
    "https://mg.lol/blog/rss/" = infrequent // tech;
    ## Ken Shirriff
    "https://www.righto.com/feeds/posts/default" = tech // infrequent;
    ## Vitalik Buterin
    "https://vitalik.ca/feed.xml" = tech // infrequent;
    ## ian (Sanctuary)
    "https://sagacioussuricata.com/feed.xml" = tech // infrequent;
    ## Bunnie Juang
    "https://www.bunniestudios.com/blog/?feed=rss2" = tech // infrequent;
    "https://blog.danieljanus.pl/atom.xml" = tech // infrequent;
    "https://ianthehenry.com/feed.xml" = tech // infrequent;
    "https://bitbashing.io/feed.xml" = tech // infrequent;
    "https://idiomdrottning.org/feed.xml" = uncat // daily;

    # (TECH; POL) COMMENTATORS
    "http://benjaminrosshoffman.com/feed" = pol // weekly;
    ## Ben Thompson
    "https://www.stratechery.com/rss" = pol // weekly;
    ## Balaji
    "https://balajis.com/rss" = pol // weekly;
    "https://www.ben-evans.com/benedictevans/rss.xml" = pol // weekly;
    "https://www.lynalden.com/feed" = pol // infrequent;
    "https://austinvernon.site/rss.xml" = tech // infrequent;
    "https://oversharing.substack.com/feed" = pol // daily;
    "https://doomberg.substack.com/feed" = tech // weekly;
    ## David Rosenthal
    "https://blog.dshr.org/rss.xml" = pol // weekly;
    ## Matt Levine
    "https://www.bloomberg.com/opinion/authors/ARbTQlRLRjE/matthew-s-levine.rss" = pol // weekly;

    # RATIONALITY/PHILOSOPHY/ETC
    "https://samkriss.substack.com/feed" = uncat // infrequent; # ... satire? phil?
    "https://unintendedconsequenc.es/feed" = rat // infrequent;
    "https://applieddivinitystudies.com/atom.xml" = rat // weekly;
    "https://slimemoldtimemold.com/feed.xml" = rat // weekly;
    "https://www.richardcarrier.info/feed" = rat // weekly;
    "https://www.gwern.net/feed.xml" = uncat // infrequent;
    ## Jason Crawford
    "https://rootsofprogress.org/feed.xml" = rat // weekly;
    ## Robin Hanson
    "https://www.overcomingbias.com/feed" = rat // daily;
    ## Scott Alexander
    "https://astralcodexten.substack.com/feed.xml" = rat // daily;
    ## Paul Christiano
    "https://sideways-view.com/feed" = rat // infrequent;
    ## Sean Carroll
    "https://www.preposterousuniverse.com/rss" = rat // infrequent;

    # COMICS
    "https://www.smbc-comics.com/comic/rss" = visual // daily;
    "https://xkcd.com/atom.xml" = visual // daily;
    "http://dilbert.com/feed" = visual // daily;

    # ART
    "https://miniature-calendar.com/feed" = visual // daily;

    # CODE
    "https://github.com/Kaiteki-Fedi/Kaiteki/commits/master.atom" = tech // infrequent;
  };

  # return only the URLs which match this category
  filterCat = cat: builtins.filter (url: rss."${url}".cat == cat) (builtins.attrNames rss);

  # represents a single RSS feed.
  opmlTerminal = url: ''<outline xmlUrl="${url}" type="rss"/>'';
  # a list of RSS feeds.
  opmlTerminals = urls: lib.strings.concatStringsSep "\n" (builtins.map opmlTerminal urls);
  # one node which packages some flat grouping of terminals.
  opmlGroup = title: urls: ''
    <outline text="${title}" title="${title}">
      ${opmlTerminals urls}
    </outline>
  '';
  # top-level OPML file which could be consumed by something else.
  opmlToplevel = bodies:
  let
    body = lib.strings.concatStringsSep "\n" bodies;
  in ''
    <?xml version="1.0" encoding="utf-8"?>
    <opml version="2.0">
      <body>${body}
      </body>
    </opml>
  '';
}
