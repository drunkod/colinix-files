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

      passthru.initFeedScript = pkgs.writeShellScript
        "init-feed"
        ''
          #!/usr/bin/env nix-shell
          #!nix-shell -i bash -p git
          name="$1"
          mkdir modules/data/feeds/sources/"$name"
          touch modules/data/feeds/sources/"$name"/default.json
          git add modules/data/feeds/sources/"$name"/default.json
        '';
    }
))
