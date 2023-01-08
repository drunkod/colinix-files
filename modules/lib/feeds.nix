{ lib, ... }:

rec {
  # PRIMARY API: generate a OPML file from a list of feeds
  feedsToOpml = feeds: opmlTopLevel (opmlGroups (partitionByCat feeds));

  # only keep feeds whose category is one of the provided
  filterByFormat = fmts: builtins.filter (feed: builtins.elem feed.format fmts);

  ## INTERNAL APIS

  # transform a list of feeds into an attrs mapping cat => [ feed0 feed1 ... ]
  partitionByCat = feeds: builtins.groupBy (f: f.cat) feeds;

  # represents a single RSS feed.
  opmlTerminal = feed: ''<outline xmlUrl="${feed.url}" type="rss"/>'';
  # a list of RSS feeds.
  opmlTerminals = feeds: lib.concatStringsSep "\n" (builtins.map opmlTerminal feeds);
  # one node which packages some flat grouping of terminals.
  opmlGroup = title: feeds: ''
    <outline text="${title}" title="${title}">
      ${opmlTerminals feeds}
    </outline>
  '';
  # a list of groups (`groupMap` is an attrs mapping groupName => [ feed0 feed1 ... ]).
  opmlGroups = groupMap: lib.concatStringsSep "\n" (
    builtins.attrValues (builtins.mapAttrs opmlGroup groupMap)
  );
  # top-level OPML file which could be consumed by something else.
  opmlTopLevel = body: ''
    <?xml version="1.0" encoding="utf-8"?>
    <opml version="2.0">
      <body>
        ${body}
      </body>
    </opml>
  '';
}
