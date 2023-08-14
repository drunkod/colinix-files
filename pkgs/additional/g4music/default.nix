{ lib
, stdenv
, fetchFromGitLab
, desktop-file-utils
, gobject-introspection
, gst_all_1
, gtk4
, libadwaita
, meson
, ninja
, pkg-config
, vala
, wrapGAppsHook
}:
stdenv.mkDerivation rec {
  pname = "g4music";
  version = "3.2";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "neithern";
    repo = "g4music";
    rev = "v${version}";
    hash = "sha256-BlHOYD4sOmJPNMzM5QA97Ah1N9tIat0Y6qxN6c5pmsw=";
  };

  nativeBuildInputs = [
    desktop-file-utils  # for update-desktop-database
    meson
    ninja
    pkg-config
    vala
    wrapGAppsHook
    gobject-introspection
  ];

  buildInputs = [
    gtk4
    libadwaita
  ] ++ (with gst_all_1; [
    gst-plugins-base
    gst-plugins-good
    gstreamer
  ]);

  meta = with lib; {
    description = "A beautiful, fast, fluent, light weight music player written in GTK4";
    homepage = "https://gitlab.gnome.org/neithern/g4music";
    license = licenses.gpl3;
    maintainers = with maintainers; [ colinsane magnouvean ];
    platforms = platforms.linux;
  };
}
