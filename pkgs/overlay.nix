(next: prev: rec {
  #### my own, non-upstreamable packages:
  sane-scripts = prev.callPackage ./sane-scripts { };
  tow-boot-pinephone = prev.callPackage ./tow-boot-pinephone { };
  tow-boot-rpi4 = prev.callPackage ./tow-boot-rpi4 { };
  bootpart-uefi-x86_64 = prev.callPackage ./bootpart-uefi-x86_64 { };
  bootpart-tow-boot-rpi-aarch64 = prev.callPackage ./bootpart-tow-boot-rpi-aarch64 {
    # not sure why i can't just do `next.callPackage` instead
    inherit tow-boot-rpi4;
  };
  bootpart-u-boot-rpi-aarch64 = prev.callPackage ./bootpart-u-boot-rpi-aarch64 {
    # not sure why i can't just do `next.callPackage` instead
    inherit ubootRaspberryPi4_64bit;
  };
  rtl8723cs-firmware = prev.callPackage ./rtl8723cs-firmware { };
  linux-megous = prev.callPackage ./linux-megous {
    kernelPatches = [
      prev.kernelPatches.bridge_stp_helper
      prev.kernelPatches.request_key_helper
    ];
  };

  sublime-music-mobile = prev.callPackage ./sublime-music-mobile { };

  #### customized packages
  fluffychat-moby = prev.callPackage ./fluffychat-moby { };
  gpodder-configured = prev.callPackage ./gpodder-configured { };
  # nixos-unstable pleroma is too far out-of-date for our db
  pleroma = prev.callPackage ./pleroma { };
  # jackett doesn't allow customization of the bind address: this will probably always be here.
  jackett = prev.callPackage ./jackett { inherit (prev) jackett; };
  # mozilla keeps nerfing itself and removing configuration options
  firefox-unwrapped = prev.callPackage ./firefox-unwrapped { };

  # patch rpi uboot with something that fixes USB HDD boot
  ubootRaspberryPi4_64bit = prev.callPackage ./ubootRaspberryPi4_64bit { };

  gocryptfs = prev.callPackage ./gocryptfs { inherit (prev) gocryptfs; };

  browserpass = prev.callPackage ./browserpass { inherit (prev) browserpass; inherit sane-scripts; };

  fractal-latest = prev.callPackage ./fractal-latest { };

  #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED
  kaiteki = prev.callPackage ./kaiteki { };
  lightdm-mobile-greeter = prev.callPackage ./lightdm-mobile-greeter { };
  browserpass-extension = prev.callPackage ./browserpass-extension { };
  gopass-native-messaging-host = prev.callPackage ./gopass-native-messaging-host { };
  tokodon = prev.libsForQt5.callPackage ./tokodon { };
  signaldctl = prev.callPackage ./signaldctl { };
  splatmoji = prev.callPackage ./splatmoji { };
  # trust-dns = prev.callPackage ./trust-dns { };
  # kaiteki = prev.kaiteki;
})

