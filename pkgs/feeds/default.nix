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
          sources_dir=modules/data/feeds/sources
          name="$1"
          url="https://$name"
          json_path="$sources_dir/$name/default.json"

          # the name could have slashes in it, so we want to mkdir -p that
          # but in a way where the least could go wrong.
          pushd "$sources_dir"; mkdir -p "$name"; popd

          ${./update.py} "$url" "$json_path"
          cat "$json_path"
        '';
    }
))
