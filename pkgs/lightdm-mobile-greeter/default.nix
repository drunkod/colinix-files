{ lib
, fetchFromGitea
, gtk3
, libhandy_0
, lightdm
, pkgs
, linkFarm
, pkg-config
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "lightdm-mobile-greeter";
  version = "0.1.2";

  src = fetchFromGitea {
    domain = "git.uninsane.org";
    owner = "colin";
    repo = "lightdm-mobile-greeter";
    rev = "v${version}";
    hash = "sha256-x7tpaHYDg6BPIc3k3zzPvZma0RYuGAMQ/z6vAP0wbWs=";
  };
  cargoHash = "sha256-5WJGnLdZd4acKPEkkTS71n4gfxhlujHWnwiMsomTYck=";

  buildInputs = [
    gtk3
    libhandy_0
    lightdm
  ];
  nativeBuildInputs = [
    pkg-config
  ];

  postInstall = ''
    mkdir -p $out/share/applications
    substitute lightdm-mobile-greeter.desktop \
      $out/share/applications/lightdm-mobile-greeter.desktop \
      --replace lightdm-mobile-greeter $out/bin/lightdm-mobile-greeter
  '';

  passthru.xgreeters = linkFarm "lightdm-mobile-greeter-xgreeters" [{
    path = "${pkgs.lightdm-mobile-greeter}/share/applications/lightdm-mobile-greeter.desktop";
    name = "lightdm-mobile-greeter.desktop";
  }];

  meta = with lib; {
    description = "A simple log in screen for use on touch screens.";
    homepage = "https://git.uninsane.org/colin/lightdm-mobile-greeter";
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
