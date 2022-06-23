(next: prev: {
  #### my own, non-upstreamable packages:
  sane-scripts = prev.callPackage ./sane-scripts { };
  #### customized packages
  # nixos-unstable pleroma is too far out-of-date for our db
  pleroma = prev.callPackage ./pleroma { };
  # jackett doesn't allow customization of the bind address: this will probably always be here.
  jackett = next.callPackage ./jackett { pkgs = prev; };
  # fix abrupt HDD poweroffs as during reboot. patching systemd requires rebuilding nearly every package.
  # systemd = import ./pkgs/systemd { pkgs = prev; };

  # patch rpi uboot with something that fixes USB HDD boot
  ubootRaspberryPi4_64bit = next.callPackage ./ubootRaspberryPi4_64bit { pkgs = prev; };

  #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED
  kaiteki = prev.callPackage ./kaiteki { };
})

