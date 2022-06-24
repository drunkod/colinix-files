(next: prev: {
  #### my own, non-upstreamable packages:
  sane-scripts = prev.callPackage ./sane-scripts { };
  tow-boot-pinephone = prev.callPackage ./tow-boot-pinephone { };
  tow-boot-rpi4 = prev.callPackage ./tow-boot-rpi4 { };
  bootpart-uefi-x86_64 = prev.callPackage ./bootpart-uefi-x86_64 { pkgs = prev; };


  #### customized packages
  # nixos-unstable pleroma is too far out-of-date for our db
  pleroma = prev.callPackage ./pleroma { };
  # jackett doesn't allow customization of the bind address: this will probably always be here.
  jackett = prev.callPackage ./jackett { pkgs = prev; };
  # fix abrupt HDD poweroffs as during reboot. patching systemd requires rebuilding nearly every package.
  # systemd = import ./pkgs/systemd { pkgs = prev; };

  # patch rpi uboot with something that fixes USB HDD boot
  ubootRaspberryPi4_64bit = prev.callPackage ./ubootRaspberryPi4_64bit { pkgs = prev; };

  #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED
  kaiteki = prev.callPackage ./kaiteki { };
})

