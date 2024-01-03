{ stdenv, lib
, fetchFromGitHub
, unstableGitUpdater
, zip
}:

stdenv.mkDerivation {
  pname = "ctrl-shift-c-should-copy";
  version = "unstable-2023-03-04";

  src = fetchFromGitHub {
    owner = "jscher2000";
    repo = "Ctrl-Shift-C-Should-Copy";
    rev = "d9e67f330d0e13fc3796e9d797f12450f75a8c6a";
    hash = "sha256-8v/b8nft7WmPOKwOR27DPG/Z9rAEPKBP4YODM+Wg8Rk=";
  };

  nativeBuildInputs = [ zip ];

  buildPhase = ''
    zip -r extension.zip ./*
  '';

  installPhase = ''
    install extension.zip $out
  '';

  passthru = {
    extid = "ctrl-shift-c-copy@jeffersonscher.com";
    updateScript = unstableGitUpdater { };
  };

  meta = {
    homepage = "https://github.com/jscher2000/Ctrl-Shift-C-Should-Copy";
    description = "Potential Firefox extension to intercept Ctrl+Shift+C, block opening developer tools, and copy the selection to the clipboard.";
    maintainer = with lib.maintainers; [ colinsane ];
  };
}
