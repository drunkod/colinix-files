{ stdenv
, lib
, fetchFromGitLab
, meson
, gettext
, glib
, python3
, gtk3
, desktop-file-utils
, ninja
, python-setup-hook
, wrapGAppsHook
, gobject-introspection
}:
let
  # optional deps: avahi, python-keyring
  pythonEnv = python3.withPackages (ps: with ps; [ dateutil pygobject3 ]);
in
stdenv.mkDerivation rec {
  pname = "mcg";
  version = "3.2.1";
  src = fetchFromGitLab {
    owner = "coderkun";
    repo = "mcg";
    rev = "v${version}";
    hash = "sha256-awPMXGruCB/2nwfDqYlc0Uu9E6VV1AleEZAw9Xdsbt8=";
  };

  nativeBuildInputs = [
    gettext  # for msgfmt
    glib
    # gtk3  # for gtk-update-icon-cache
    meson
    ninja
    desktop-file-utils  # for update-desktop-database
    wrapGAppsHook
    gobject-introspection  # needed so wrapGAppsHook includes GI_TYPEPATHS for gtk3
  ];

  buildInputs = [
    pythonEnv
    glib
    gtk3
  ];

  meta = with lib; {
    description = "CoverGrid (mcg) is a client for the Music Player Daemon (MPD), focusing on albums instead of single tracks.";
    homepage = "https://www.suruatoel.xyz/codes/mcg";
    platforms = platforms.linux;
    # license = TODO
    maintainers = with maintainers; [ colinsane ];
  };
}
