{ lib
, pkgs
, stdenv
}:

stdenv.mkDerivation {
  name = "sane-scripts";

  src = ./src;

  # See: https://nixos.org/nixpkgs/manual/#ssec-stdenv-dependencies
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
