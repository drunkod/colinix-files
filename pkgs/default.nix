# this supports being used as an overlay or in a standalone context
# - if overlay, invoke as `(final: prev: import ./. { inherit final; pkgs = prev; })`
# - if standalone: `import ./. { inherit pkgs; }`
#
# using the correct invocation is critical if any packages mentioned here are
# additionally patched elsewhere
#
{ pkgs ? import <nixpkgs> {}, final ? null }:
let
  lib = pkgs.lib;
  unpatched = pkgs;

  pythonPackagesOverlay = py-final: py-prev: import ./python-packages {
    inherit (py-final) callPackage;
  };
  final' = if final != null then final else (pkgs // sane);
  sane = with final'; {
    sane-data = import ../modules/data { inherit lib; };
    sane-lib = import ../modules/lib final';

    ### ADDITIONAL PACKAGES
    bootpart-uefi-x86_64 = callPackage ./additional/bootpart-uefi-x86_64 { };
    browserpass-extension = callPackage ./additional/browserpass-extension { };
    cargoDocsetHook = callPackage ./additional/cargo-docset/hook.nix { };
    feeds = lib.recurseIntoAttrs (callPackage ./additional/feeds { });
    gopass-native-messaging-host = callPackage ./additional/gopass-native-messaging-host { };
    gpodder-configured = callPackage ./additional/gpodder-configured { };
    lightdm-mobile-greeter = callPackage ./additional/lightdm-mobile-greeter { };
    linux-megous = callPackage ./additional/linux-megous { };
    mx-sanebot = callPackage ./additional/mx-sanebot { };
    rtl8723cs-firmware = callPackage ./additional/rtl8723cs-firmware { };
    sane-scripts = callPackage ./additional/sane-scripts { };
    static-nix-shell = callPackage ./additional/static-nix-shell { };
    sublime-music-mobile = callPackage ./additional/sublime-music-mobile { };
    tow-boot-pinephone = callPackage ./additional/tow-boot-pinephone { };

    # packages i haven't used for a while, may or may not still work
    # fluffychat-moby = callPackage ./additional/fluffychat-moby { };
    # fractal-latest = callPackage ./additional/fractal-latest { };
    # kaiteki = callPackage ./additional/kaiteki { };
    # tokodon = libsForQt5.callPackage ./additional/tokodon { };

    # old rpi packages that may or may not still work
    # bootpart-tow-boot-rpi-aarch64 = callPackage ./additional/bootpart-tow-boot-rpi-aarch64 { };
    # bootpart-u-boot-rpi-aarch64 = callPackage ./additional/bootpart-u-boot-rpi-aarch64 { };
    # tow-boot-rpi4 = callPackage ./additional/tow-boot-rpi4 { };
    # patch rpi uboot with something that fixes USB HDD boot
    # ubootRaspberryPi4_64bit = callPackage ./additional/ubootRaspberryPi4_64bit { };

    # provided by nixpkgs patch or upstream PR
    # cargo-docset = callPackage ./additional/cargo-docset { };
    # splatmoji = callPackage ./additional/splatmoji { };


    ### PATCHED PACKAGES

    # XXX: the `inherit`s here are because:
    # - pkgs.callPackage draws from the _final_ package set.
    # - unpatched.XYZ draws (selectively) from the _unpatched_ package set.
    # see <overlays/pkgs.nix>
    browserpass = callPackage ./patched/browserpass { inherit (unpatched) browserpass; };

    # mozilla keeps nerfing itself and removing configuration options
    firefox-unwrapped = callPackage ./patched/firefox-unwrapped { inherit (unpatched) firefox-unwrapped; };

    gnome = unpatched.gnome.overrideScope' (gself: gsuper: {
      gnome-control-center = gself.callPackage ./patched/gnome-control-center {
        inherit (gsuper) gnome-control-center;
      };
    });

    gocryptfs = callPackage ./patched/gocryptfs { inherit (unpatched) gocryptfs; };

    # jackett doesn't allow customization of the bind address: this will probably always be here.
    jackett = callPackage ./patched/jackett { inherit (unpatched) jackett; };

    lemmy-server = callPackage ./patched/lemmy-server { inherit (unpatched) lemmy-server; };

    phoc = callPackage ./patched/phoc { inherit (unpatched) phoc; };


    ### PYTHON PACKAGES
    pythonPackagesExtensions = (unpatched.pythonPackagesExtensions or []) ++ [
      pythonPackagesOverlay
    ];
    # when this scope's applied as an overlay pythonPackagesExtensions is propagated as desired.
    # but when freestanding (e.g. NUR), it never gets plumbed into the outer pkgs, so we have to do that explicitly.
    python3 = unpatched.python3.override {
      packageOverrides = pythonPackagesOverlay;
    };
  };
in sane
