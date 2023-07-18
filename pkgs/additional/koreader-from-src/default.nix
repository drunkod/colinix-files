{ lib, stdenv
, fetchurl
, makeWrapper
, fetchFromGitHub
, dpkg
, glib
, gnutar
, gtk3-x11
, luajit
, sdcv
, SDL2 }:
let
  luajit_lua52 = luajit.override { enable52Compat = true; };
in
stdenv.mkDerivation rec {
  pname = "koreader-from-src";
  version = "2023.06";
  src = fetchFromGitHub {
    repo = "koreader";
    owner = "koreader";
    rev = "v${version}";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ makeWrapper dpkg ];
  buildInputs = [
    glib
    gnutar
    gtk3-x11
    luajit_lua52
    sdcv
    SDL2
  ];

  buildPhase = ''
    make TARGET=debian DEBIAN=1 INSTALL_DIR="$out"
  '';

  installPhase = ''
    make TARGET=debian DEBIAN=1 INSTALL_DIR="$out" update
  '';

  meta = with lib; {
    homepage = "https://github.com/koreader/koreader";
    description =
      "An ebook reader application supporting PDF, DjVu, EPUB, FB2 and many more formats, running on Cervantes, Kindle, Kobo, PocketBook and Android devices";
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = platforms.linux;
    license = licenses.agpl3Only;
    maintainers = with maintainers; [ colinsane contrun neonfuz];
  };
}
