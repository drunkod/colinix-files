(next: prev: rec {
  #### my own, non-upstreamable packages:
  sane-scripts = prev.callPackage ./sane-scripts { };
  tow-boot-pinephone = prev.callPackage ./tow-boot-pinephone { };
  tow-boot-rpi4 = prev.callPackage ./tow-boot-rpi4 { };
  bootpart-uefi-x86_64 = prev.callPackage ./bootpart-uefi-x86_64 { pkgs = prev; };
  bootpart-tow-boot-rpi-aarch64 = prev.callPackage ./bootpart-tow-boot-rpi-aarch64 {
    # not sure why i can't just do pkgs = next here
    pkgs = prev // { inherit tow-boot-rpi4; };
  };
  bootpart-u-boot-rpi-aarch64 = prev.callPackage ./bootpart-u-boot-rpi-aarch64 {
    # not sure why i can't just do pkgs = next here
    pkgs = prev // { inherit ubootRaspberryPi4_64bit; };
  };
  rtl8723cs-firmware = prev.callPackage ./rtl8723cs-firmware { };
  linux-megous = prev.callPackage ./linux-megous {
    kernelPatches = [
      prev.kernelPatches.bridge_stp_helper
      prev.kernelPatches.request_key_helper
    ];
  };

  #### customized packages
  fluffychat-moby = prev.callPackage ./fluffychat-moby { pkgs = prev; };
  gpodder-configured = prev.callPackage ./gpodder-configured { pkgs = prev; };
  # nixos-unstable pleroma is too far out-of-date for our db
  pleroma = prev.callPackage ./pleroma { };
  # jackett doesn't allow customization of the bind address: this will probably always be here.
  jackett = prev.callPackage ./jackett { pkgs = prev; };
  # mozilla keeps nerfing itself and removing configuration options
  firefox-unwrapped = prev.callPackage ./firefox-unwrapped { pkgs = prev; };
  # fix abrupt HDD poweroffs as during reboot. patching systemd requires rebuilding nearly every package.
  # systemd = import ./pkgs/systemd { pkgs = prev; };

  # patch rpi uboot with something that fixes USB HDD boot
  ubootRaspberryPi4_64bit = prev.callPackage ./ubootRaspberryPi4_64bit { pkgs = prev; };

  #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED
  kaiteki = prev.callPackage ./kaiteki { };
  # kaiteki = prev.kaiteki;
  # TODO: upstream, or delete nabla
  nabla = prev.callPackage ./nabla { };
})

