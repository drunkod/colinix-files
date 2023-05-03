{ pkgs, lib ? pkgs.lib, unpatched ? pkgs }:
let
  me = lib.makeScope pkgs.newScope (self: with self; {
    # XXX: the `inherit`s here are because:
    # - pkgs.callPackage draws from the _final_ package set.
    # - unpatched.XYZ draws (selectively) from the _unpatched_ package set.
    # see <overlays/pkgs.nix>
    browserpass = callPackage ./browserpass { inherit (unpatched) browserpass; };

    # mozilla keeps nerfing itself and removing configuration options
    firefox-unwrapped = callPackage ./firefox-unwrapped { inherit (unpatched) firefox-unwrapped; };

    gocryptfs = callPackage ./gocryptfs { inherit (unpatched) gocryptfs; };

    # jackett doesn't allow customization of the bind address: this will probably always be here.
    jackett = callPackage ./jackett { inherit (unpatched) jackett; };
  });
in me.packages me
