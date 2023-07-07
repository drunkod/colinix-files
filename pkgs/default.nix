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

  pythonPackagesOverlayFor = pkgs: py-final: py-prev: import ./python-packages {
    inherit (py-final) callPackage;
    inherit pkgs;
  };
  final' = if final != null then final else pkgs.appendOverlays [(_: _: sane)];
  sane = with final'; {
    sane-data = import ../modules/data { inherit lib sane-lib; };
    sane-lib = import ../modules/lib final';

    ### ADDITIONAL PACKAGES
    alsa-ucm-conf-sane = callPackage ./additional/alsa-ucm-conf-sane { };
    bonsai = unpatched.bonsai or (callPackage ./additional/bonsai { });
    bootpart-uefi-x86_64 = callPackage ./additional/bootpart-uefi-x86_64 { };
    browserpass-extension = callPackage ./additional/browserpass-extension { };
    cargoDocsetHook = callPackage ./additional/cargo-docset/hook.nix { };
    feeds = lib.recurseIntoAttrs (callPackage ./additional/feeds { });
    lemoa = callPackage ./additional/lemoa { };
    jellyfin-media-player-qt6 = callPackage ./additional/jellyfin-media-player-qt6 { };
    gopass-native-messaging-host = callPackage ./additional/gopass-native-messaging-host { };
    gpodder-adaptive = callPackage ./additional/gpodder-adaptive { };
    gpodder-adaptive-configured = callPackage ./additional/gpodder-configured {
      gpodder = final'.gpodder-adaptive;
    };
    gpodder-configured = callPackage ./additional/gpodder-configured { };
    hare-ev = unpatched.hare-ev or (callPackage ./additional/hare-ev { });
    hare-json = unpatched.hare-json or (callPackage ./additional/hare-json { });
    lightdm-mobile-greeter = callPackage ./additional/lightdm-mobile-greeter { };
    linux-megous = callPackage ./additional/linux-megous { };
    mx-sanebot = callPackage ./additional/mx-sanebot { };
    rtl8723cs-firmware = callPackage ./additional/rtl8723cs-firmware { };
    # TODO: use `recurseIntoAttrs` ?
    sane-scripts = callPackage ./additional/sane-scripts { };
    static-nix-shell = callPackage ./additional/static-nix-shell { };
    sublime-music-mobile = callPackage ./additional/sublime-music-mobile { };
    sxmo-utils = callPackage ./additional/sxmo-utils { };
    tow-boot-pinephone = callPackage ./additional/tow-boot-pinephone { };
    tree-sitter-nix-shell = callPackage ./additional/tree-sitter-nix-shell { };
    unftp = callPackage ./additional/unftp { };
    xdg-terminal-exec = callPackage ./additional/xdg-terminal-exec { };
    zecwallet-light-cli = callPackage ./additional/zecwallet-light-cli { };

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
    # i still conditionally callPackage these to make them available to external consumers (like NUR)
    splatmoji = unpatched.splatmoji or (callPackage ./additional/splatmoji { });


    ### PATCHED PACKAGES

    # XXX: the `inherit`s here are because:
    # - pkgs.callPackage draws from the _final_ package set.
    # - unpatched.XYZ draws (selectively) from the _unpatched_ package set.
    # see <overlays/pkgs.nix>

    # XXX patching this is... really costly.
    # prefer to set ALSA_CONFIG_UCM2 = "${pkgs.alsa-ucm-conf-sane}/share/alsa/ucm2" if possible instead.
    # alsa-project = unpatched.alsa-project.overrideScope' (sself: ssuper: {
    #   alsa-ucm-conf = sself.callPackage ./additional/alsa-ucm-conf-sane { inherit (ssuper) alsa-ucm-conf; };
    # });

    browserpass = callPackage ./patched/browserpass { inherit (unpatched) browserpass; };

    cozy = callPackage ./patched/cozy { inherit (unpatched) cozy; };

    # mozilla keeps nerfing itself and removing configuration options
    firefox-unwrapped = callPackage ./patched/firefox-unwrapped { inherit (unpatched) firefox-unwrapped; };

    gnome = unpatched.gnome.overrideScope' (gself: gsuper: {
      gnome-control-center = gself.callPackage ./patched/gnome-control-center {
        inherit (gsuper) gnome-control-center;
      };
    });

    gocryptfs = callPackage ./patched/gocryptfs { inherit (unpatched) gocryptfs; };

    helix = callPackage ./patched/helix { inherit (unpatched) helix; };

    # jackett doesn't allow customization of the bind address: this will probably always be here.
    jackett = callPackage ./patched/jackett { inherit (unpatched) jackett; };

    lemmy-server = callPackage ./patched/lemmy-server { inherit (unpatched) lemmy-server; };

    phoc = callPackage ./patched/phoc { inherit (unpatched) phoc; };


    ### PYTHON PACKAGES
    pythonPackagesExtensions = (unpatched.pythonPackagesExtensions or []) ++ [
      (pythonPackagesOverlayFor final')
    ];
    # when this scope's applied as an overlay pythonPackagesExtensions is propagated as desired.
    # but when freestanding (e.g. NUR), it never gets plumbed into the outer pkgs, so we have to do that explicitly.
    python3 = unpatched.python3.override {
      packageOverrides = pythonPackagesOverlayFor final';
    };
  };
in sane
