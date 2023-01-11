{ lib
, pkgs
}:

(lib.makeScope pkgs.newScope (self:
  let
    # TODO: dependency-inject this.
    sane-data = import ../../modules/data { inherit lib; };
    template = self.callPackage ./template.nix;
    feed-pkgs = lib.mapAttrs
      (name: feed-details: template {
        feedName = name;
        jsonPath = "modules/data/feeds/sources/${name}/default.json";
        inherit (feed-details) url;
      })
      sane-data.feeds;
    update-scripts = lib.mapAttrsToList
      (name: feed: builtins.concatStringsSep " " feed.passthru.updateScript)
      feed-pkgs;
  in
    feed-pkgs // {
      passthru.updateScript = pkgs.writeShellScript
        "feeds-update"
        (builtins.concatStringsSep "\n" update-scripts);
    }
))
