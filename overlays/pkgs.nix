(next: prev:
  let
    sane = rec {
      #### my own, non-upstreamable packages:
      sane-scripts = prev.callPackage ../pkgs/sane-scripts { };
      feeds = prev.callPackage ../pkgs/feeds { };
      tow-boot-pinephone = prev.callPackage ../pkgs/tow-boot-pinephone { };
      tow-boot-rpi4 = prev.callPackage ../pkgs/tow-boot-rpi4 { };
      bootpart-uefi-x86_64 = prev.callPackage ../pkgs/bootpart-uefi-x86_64 { };
      bootpart-tow-boot-rpi-aarch64 = prev.callPackage ../pkgs/bootpart-tow-boot-rpi-aarch64 {
        # not sure why i can't just do `next.callPackage` instead
        inherit tow-boot-rpi4;
      };
      bootpart-u-boot-rpi-aarch64 = prev.callPackage ../pkgs/bootpart-u-boot-rpi-aarch64 {
        # not sure why i can't just do `next.callPackage` instead
        inherit ubootRaspberryPi4_64bit;
      };
      rtl8723cs-firmware = prev.callPackage ../pkgs/rtl8723cs-firmware { };
      linux-megous = prev.callPackage ../pkgs/linux-megous {
        kernelPatches = [
          prev.kernelPatches.bridge_stp_helper
          prev.kernelPatches.request_key_helper
        ];
      };

      sublime-music-mobile = prev.callPackage ../pkgs/sublime-music-mobile { };

      #### customized packages
      fluffychat-moby = prev.callPackage ../pkgs/fluffychat-moby { };
      gpodder-configured = prev.callPackage ../pkgs/gpodder-configured { };
      # nixos-unstable pleroma is too far out-of-date for our db
      pleroma = prev.callPackage ../pkgs/pleroma { };
      # jackett doesn't allow customization of the bind address: this will probably always be here.
      jackett = prev.callPackage ../pkgs/jackett { inherit (prev) jackett; };
      # mozilla keeps nerfing itself and removing configuration options
      firefox-unwrapped = prev.callPackage ../pkgs/firefox-unwrapped { };

      # patch rpi uboot with something that fixes USB HDD boot
      ubootRaspberryPi4_64bit = prev.callPackage ../pkgs/ubootRaspberryPi4_64bit { };

      gocryptfs = prev.callPackage ../pkgs/gocryptfs { inherit (prev) gocryptfs; };

      browserpass = prev.callPackage ../pkgs/browserpass { inherit (prev) browserpass; inherit sane-scripts; };

      fractal-latest = prev.callPackage ../pkgs/fractal-latest { };

      #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED

      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: {
          feedsearch-crawler = py-final.callPackage ../pkgs/feedsearch-crawler { };
        })
      ];

      kaiteki = prev.callPackage ../pkgs/kaiteki { };
      lightdm-mobile-greeter = prev.callPackage ../pkgs/lightdm-mobile-greeter { };
      browserpass-extension = prev.callPackage ../pkgs/browserpass-extension { };
      gopass-native-messaging-host = prev.callPackage ../pkgs/gopass-native-messaging-host { };
      tokodon = prev.libsForQt5.callPackage ../pkgs/tokodon { };
      splatmoji = prev.callPackage ../pkgs/splatmoji { };

      # provided by nixpkgs patch or upstream preview
      # signaldctl = prev.callPackage ../pkgs/signaldctl { };
      # trust-dns = prev.callPackage ../pkgs/trust-dns { };
    };
  in sane // { inherit sane; }
)

