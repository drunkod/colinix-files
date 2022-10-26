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
  version = "6";

  src = fetchFromGitea {
    domain = "git.raatty.club";
    owner = "raatty";
    repo = "lightdm-mobile-greeter";
    rev = "${version}";
    hash = "sha256-uqsYOHRCOmd3tpJdndZFQ/tznZ660NhB+gE2154kJuM=";
  };
  cargoHash = "sha256-JV8NQdZAG4EetRHwbi0dD0uIOUkn5hvzry+5WB7TCO4=";

  cargoPatches = [
    ./cargo_lock-fix_lightdm_rs_url.patch
  ];

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
