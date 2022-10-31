{ lib
, stdenv
, fetchFromGitHub
, cmake
, extra-cmake-modules
, kconfig
, kdbusaddons
, ki18n
, kirigami2
, knotifications
, libwebsockets
, pkg-config
, qqc2-desktop-style
, qtbase
, qtkeychain
, qtmultimedia
, qtquickcontrols2
, qttools
, qtwebsockets
, wrapQtAppsHook
}:

stdenv.mkDerivation rec {
  pname = "tokodon";
  version = "22.09";

  src = fetchFromGitHub {
    owner = "KDE";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-wHE8HPnjXd+5UG5WEMd7+m1hu2G3XHq/eVQNznvS/zc=";
  };

  nativeBuildInputs = [
    cmake
    extra-cmake-modules
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    kconfig
    kdbusaddons
    ki18n
    kirigami2
    knotifications
    qqc2-desktop-style
    qtbase
    qtkeychain
    qtmultimedia
    qtquickcontrols2
    qttools
    qtwebsockets
  ];

  meta = with lib; {
    description = "A Mastodon client for Plasma and Plasma Mobile";
    homepage = src.meta.homepage;
    license = licenses.gpl3Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ matthiasbeyer ];
  };
}

