(next: prev:
  with next;
  let
    sane = rec {
      sane-lib = import ../modules/lib next;
      #### my own, non-upstreamable packages:
      static-nix-shell = callPackages ../pkgs/static-nix-shell { };
      sane-scripts = callPackage ../pkgs/sane-scripts { };
      mx-sanebot = callPackage ../pkgs/mx-sanebot { };
      feeds = recurseIntoAttrs (callPackage ../pkgs/feeds { });
      tow-boot-pinephone = callPackage ../pkgs/tow-boot-pinephone { };
      tow-boot-rpi4 = callPackage ../pkgs/tow-boot-rpi4 { };
      bootpart-uefi-x86_64 = callPackage ../pkgs/bootpart-uefi-x86_64 { };
      bootpart-tow-boot-rpi-aarch64 = callPackage ../pkgs/bootpart-tow-boot-rpi-aarch64 { };
      bootpart-u-boot-rpi-aarch64 = callPackage ../pkgs/bootpart-u-boot-rpi-aarch64 { };
      rtl8723cs-firmware = callPackage ../pkgs/rtl8723cs-firmware { };
      linux-megous = callPackage ../pkgs/linux-megous {
        kernelPatches = [
          prev.kernelPatches.bridge_stp_helper
          prev.kernelPatches.request_key_helper
        ];
      };

      sublime-music-mobile = callPackage ../pkgs/sublime-music-mobile { };

      #### customized packages
      fluffychat-moby = callPackage ../pkgs/fluffychat-moby { };
      gpodder-configured = callPackage ../pkgs/gpodder-configured { };
      # jackett doesn't allow customization of the bind address: this will probably always be here.
      jackett = callPackage ../pkgs/jackett { inherit (prev) jackett; };
      # mozilla keeps nerfing itself and removing configuration options
      firefox-unwrapped = callPackage ../pkgs/firefox-unwrapped { inherit (prev) firefox-unwrapped; };

      # patch rpi uboot with something that fixes USB HDD boot
      ubootRaspberryPi4_64bit = callPackage ../pkgs/ubootRaspberryPi4_64bit { };

      gocryptfs = callPackage ../pkgs/gocryptfs { inherit (prev) gocryptfs; };

      browserpass = callPackage ../pkgs/browserpass { inherit (prev) browserpass; };

      fractal-latest = callPackage ../pkgs/fractal-latest { };

      #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED

      cargo-docset = callPackage ../pkgs/cargo-docset { };

      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (py-final: py-prev: {
          feedsearch-crawler = py-final.callPackage ../pkgs/feedsearch-crawler { };
        })
      ];

      # XXX: needs rework before it can build: kaiteki = callPackage ../pkgs/kaiteki { };
      lightdm-mobile-greeter = callPackage ../pkgs/lightdm-mobile-greeter { };
      browserpass-extension = callPackage ../pkgs/browserpass-extension { };
      gopass-native-messaging-host = callPackage ../pkgs/gopass-native-messaging-host { };
      tokodon = prev.libsForQt5.callPackage ../pkgs/tokodon { };

      # provided by nixpkgs patch or upstream preview
      # splatmoji = callPackage ../pkgs/splatmoji { };
    };
  in sane // { inherit sane; }
)

