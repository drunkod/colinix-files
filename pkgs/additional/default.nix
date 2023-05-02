# { callPackage, callPackages, libsForQt5, pkgs, recurseIntoAttrs }:
pkgs:
let
  inherit (pkgs) callPackage callPackages libsForQt5 recurseIntoAttrs;
in {
  sane-lib = import ../../modules/lib pkgs;

  bootpart-tow-boot-rpi-aarch64 = callPackage ./bootpart-tow-boot-rpi-aarch64 { };
  bootpart-u-boot-rpi-aarch64 = callPackage ./bootpart-u-boot-rpi-aarch64 { };
  bootpart-uefi-x86_64 = callPackage ./bootpart-uefi-x86_64 { };
  browserpass-extension = callPackage ./browserpass-extension { };
  cargo-docset = callPackage ./cargo-docset { };
  feeds = recurseIntoAttrs (callPackage ./feeds { });
  fluffychat-moby = callPackage ./fluffychat-moby { };
  fractal-latest = callPackage ./fractal-latest { };
  gopass-native-messaging-host = callPackage ./gopass-native-messaging-host { };
  gpodder-configured = callPackage ./gpodder-configured { };
  kaiteki = callPackage ./kaiteki { };
  lightdm-mobile-greeter = callPackage ./lightdm-mobile-greeter { };
  linux-megous = callPackage ./linux-megous { };
  mx-sanebot = callPackage ./mx-sanebot { };
  rtl8723cs-firmware = callPackage ./rtl8723cs-firmware { };
  sane-scripts = callPackage ./sane-scripts { };
  static-nix-shell = callPackages ./static-nix-shell { };
  sublime-music-mobile = callPackage ./sublime-music-mobile { };
  tokodon = libsForQt5.callPackage ./tokodon { };
  tow-boot-pinephone = callPackage ./tow-boot-pinephone { };
  tow-boot-rpi4 = callPackage ./tow-boot-rpi4 { };

  # patch rpi uboot with something that fixes USB HDD boot
  ubootRaspberryPi4_64bit = callPackage ./ubootRaspberryPi4_64bit { };

  # provided by nixpkgs patch or upstream PR
  # splatmoji = callPackage ./splatmoji { };
}
