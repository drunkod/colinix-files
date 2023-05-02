pkgs:
let
  inherit (pkgs) callPackage;
in {
  # XXX: the `inherit`s here are because:
  # - pkgs.callPackage draws from the _final_ package set.
  # - pkgs.XYZ draws (selectively) from the _previous_ package set.
  # see <overlays/pkgs.nix>
  browserpass = callPackage ./browserpass { inherit (pkgs) browserpass; };

  # mozilla keeps nerfing itself and removing configuration options
  firefox-unwrapped = callPackage ./firefox-unwrapped { inherit (pkgs) firefox-unwrapped; };

  gocryptfs = callPackage ./gocryptfs { inherit (pkgs) gocryptfs; };

  # jackett doesn't allow customization of the bind address: this will probably always be here.
  jackett = callPackage ./jackett { inherit (pkgs) jackett; };
}
