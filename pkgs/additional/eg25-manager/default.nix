# package based on:
# - <https://github.com/NixOS/mobile-nixos/pull/573>

{ lib
, stdenv
, fetchFromGitLab
, gnugrep
, meson
, ninja
, pkg-config
, scdoc
, curl
, glib
, libgpiod
, libgudev
, libusb1
, modemmanager
}:

stdenv.mkDerivation rec {
  pname = "eg25-manager";
  version = "0.4.6";

  src = fetchFromGitLab {
    owner = "mobian1";
    repo = "eg25-manager";
    rev = version;
    hash = "sha256-2JsdwK1ZOr7ljNHyuUMzVCpl+HV0C5sA5LAOkmELqag=";
  };

  postPatch = ''
    substituteInPlace 'udev/80-modem-eg25.rules' \
      --replace '/bin/grep' '${gnugrep}/bin/grep'
  '';

  depsBuildBuild = [
    pkg-config
  ];

  nativeBuildInputs = [
    glib # Contains gdbus-codegen program
    meson
    ninja
    pkg-config
    scdoc
  ];

  buildInputs = [
    curl
    glib
    libgpiod
    libgudev
    libusb1
    modemmanager
  ];

  meta = with lib; {
    description = "Manager daemon for the Quectel EG25 mobile broadband modem";
    homepage = "https://gitlab.com/mobian1/eg25-manager";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    # needs to be made compatible with libgpiod 2.0 API. see:
    # - <https://github.com/NixOS/mobile-nixos/pull/573#issuecomment-1666739462>
    # - <https://gitlab.com/mobian1/eg25-manager/-/issues/45>
    # nixpkgs libgpiod was bumped 2023-07-29:
    # - <https://github.com/NixOS/nixpkgs/pull/246018>
    broken = true;
  };
}
