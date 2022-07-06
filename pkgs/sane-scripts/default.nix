{ lib
, pkgs
, stdenv
}:

stdenv.mkDerivation {
  name = "sane-scripts";

  src = ./src;

  # See: https://nixos.org/nixpkgs/manual/#ssec-stdenv-dependencies
  # TODO: we aren't propagating all dependencies here (e.g. rmlint)
  buildInputs = [ pkgs.rsync ];

  installPhase = ''
    mkdir -p "$out"
    cp -R * "$out"/
  '';

  meta = {
    description = "collection of scripts associated with uninsane systems";
    homepage = "https://git.uninsane.org";
    platforms = lib.platforms.all;
  };
}
