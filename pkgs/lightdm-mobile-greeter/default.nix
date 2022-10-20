{ lib
, fetchFromGitea
, gtk3
, libhandy_0
, lightdm
, pkg-config
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "lightdm-mobile-greeter";
  version = "0.1.1";

  src = fetchFromGitea {
    domain = "git.uninsane.org";
    owner = "colin";
    repo = "lightdm-mobile-greeter";
    rev = "v${version}";
    hash = "sha256-jcILF7i+1kZKgAx5YoOBRPI66gadpSZXkn617ZcKnR8=";
  };
  cargoHash = "sha256-KUJZzbE6nKBITO0iTuFGVOEKyA+RfcBiC1G+Rg0/00w=";

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

  meta = with lib; {
    description = "A simple log in screen for use on touch screens.";
    homepage = "https://git.uninsane.org/colin/lightdm-mobile-greeter";
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
