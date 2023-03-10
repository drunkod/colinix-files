(next: prev:
  let
    sane = rec {
      #### my own, non-upstreamable packages:
      sane-scripts = next.callPackage ../pkgs/sane-scripts { };
      feeds = next.callPackage ../pkgs/feeds { };
      tow-boot-pinephone = next.callPackage ../pkgs/tow-boot-pinephone { };
      tow-boot-rpi4 = next.callPackage ../pkgs/tow-boot-rpi4 { };
      bootpart-uefi-x86_64 = next.callPackage ../pkgs/bootpart-uefi-x86_64 { };
      bootpart-tow-boot-rpi-aarch64 = next.callPackage ../pkgs/bootpart-tow-boot-rpi-aarch64 { };
      bootpart-u-boot-rpi-aarch64 = next.callPackage ../pkgs/bootpart-u-boot-rpi-aarch64 { };
      rtl8723cs-firmware = next.callPackage ../pkgs/rtl8723cs-firmware { };
      linux-megous = next.callPackage ../pkgs/linux-megous {
        kernelPatches = [
          prev.kernelPatches.bridge_stp_helper
          prev.kernelPatches.request_key_helper
        ];
      };

      sublime-music-mobile = next.callPackage ../pkgs/sublime-music-mobile { };

      #### customized packages
      fluffychat-moby = next.callPackage ../pkgs/fluffychat-moby { };
      gpodder-configured = next.callPackage ../pkgs/gpodder-configured { };
      # jackett doesn't allow customization of the bind address: this will probably always be here.
      jackett = next.callPackage ../pkgs/jackett { inherit (prev) jackett; };
      # mozilla keeps nerfing itself and removing configuration options
      firefox-unwrapped = next.callPackage ../pkgs/firefox-unwrapped { inherit (prev) firefox-unwrapped; };

      # patch rpi uboot with something that fixes USB HDD boot
      ubootRaspberryPi4_64bit = next.callPackage ../pkgs/ubootRaspberryPi4_64bit { };

      gocryptfs = next.callPackage ../pkgs/gocryptfs { inherit (prev) gocryptfs; };

      browserpass = next.callPackage ../pkgs/browserpass { inherit (prev) browserpass; };

      fractal-latest = next.callPackage ../pkgs/fractal-latest { };

      #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED

      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: {
          feedsearch-crawler = py-final.callPackage ../pkgs/feedsearch-crawler { };
        })
      ];

      kaiteki = next.callPackage ../pkgs/kaiteki { };
      lightdm-mobile-greeter = next.callPackage ../pkgs/lightdm-mobile-greeter { };
      browserpass-extension = next.callPackage ../pkgs/browserpass-extension { };
      gopass-native-messaging-host = next.callPackage ../pkgs/gopass-native-messaging-host { };
      tokodon = prev.libsForQt5.callPackage ../pkgs/tokodon { };

      # provided by nixpkgs patch or upstream preview
      # splatmoji = next.callPackage ../pkgs/splatmoji { };
    };
  in sane // { inherit sane; }
)

