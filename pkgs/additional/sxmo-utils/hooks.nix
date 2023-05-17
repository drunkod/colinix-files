{ stdenv
, sxmo-utils
}:
stdenv.mkDerivation rec {
  pname = "sxmo-utils-default-hooks";
  inherit (sxmo-utils) version;

  installPhase = ''
    mkdir -p $out
    ln -s ${sxmo-utils}/share/sxmo/default_hooks $out/bin
  '';
}
