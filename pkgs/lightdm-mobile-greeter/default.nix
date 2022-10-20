{ lib
, fetchFromGitea
, gtk3
, libhandy_0
, lightdm
, rustPlatform
}:

rustPlatform.buildRustPackage rec {
  pname = "lightdm-mobile-greeter";
  version = "6";

  src = fetchFromGitea {
    domain = "git.uninsane.org";
    owner = "colin";
    repo = "lightdm-mobile-greeter";
    # rev = version;  # TODO: tag/bump release in rust repo
    rev = "93f34bac631e583e4d384eeb19f9f96da8672048";
    hash = "sha256-77J/qLYliXPvYJLtHPvu1P67I2eOxVwYV3JozbG6aZs=";
  };
  cargoHash = "sha256-yMXe+K1HolvW/+pSEVHT4Xz9ON50/EkBioytA3E4bYI=";

  buildInputs = [
    gtk3
    libhandy_0
    lightdm
  ];

  meta = with lib; {
    description = "A simple log in screen for use on touch screens.";
    homepage = "https://git.uninsane.org/colin/lightdm-mobile-greeter";
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
    license = licenses.mit;
  };
}
