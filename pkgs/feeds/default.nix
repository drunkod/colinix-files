{ lib
, callPackage
, python3
, stdenv
, writeShellScript
}:

let
  # TODO: dependency-inject this.
  sane-data = import ../../modules/data { inherit lib; };
  template = callPackage ./template.nix;
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
in rec {  # TODO: make this a scope
  inherit feed-pkgs;
  update = stdenv.mkDerivation {
    pname = "update";
    version = "0.1.0";
    src = ./.;
    patchPhase =
      let
        pyEnv = python3.withPackages (ps: [ ps.feedsearch-crawler ]);
      in ''
      substituteInPlace ./update.py \
        --replace "#!/usr/bin/env nix-shell" "#!${pyEnv.interpreter}"
    '';
    installPhase = ''
      mkdir -p $out/bin
      mv update.py $out/bin/update.py
    '';
  };
  passthru = {
    updateScript = writeShellScript
      "feeds-update"
      (builtins.concatStringsSep "\n" update-scripts);

    initFeedScript = writeShellScript
      "init-feed"
      ''
        # this is the `nix run '.#init-feed' <url>` script`
        sources_dir=modules/data/feeds/sources
        # prettify the URL, by default
        name=$( \
          echo "$1" \
          | sed 's|^https://||' \
          | sed 's|^http://||' \
          | sed 's|^www\.||' \
          | sed 's|/+$||' \
        )
        json_path="$sources_dir/$name/default.json"

        # the name could have slashes in it, so we want to mkdir -p that
        # but in a way where the least could go wrong.
        pushd "$sources_dir"; mkdir -p "$name"; popd

        ${update}/bin/update.py "$name" "$json_path"
        cat "$json_path"
      '';
  };
}
