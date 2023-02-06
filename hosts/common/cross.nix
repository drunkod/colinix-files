{ config, lib, pkgs, ... }:

let
  # these are the overlays which we *also* pass through to the cross and emulated package sets.
  # TODO: refactor to not specify same overlay in multiple places (here and flake.nix).
  overlays = [
    (import ./../../overlays/pkgs.nix)
    (import ./../../overlays/pins.nix)
  ];
  mkCrossFrom = localSystem: pkgs:
    import pkgs.path {
      inherit localSystem;  # localSystem is equivalent to buildPlatform
      crossSystem = pkgs.stdenv.hostPlatform.system;
      inherit (config.nixpkgs) config;
      inherit overlays;
    };
  mkEmulated = pkgs:
    import pkgs.path {
      localSystem = pkgs.stdenv.hostPlatform.system;
      inherit (config.nixpkgs) config;
      inherit overlays;
    };
in
{
  # options = {
  #   perlPackageOverrides = lib.mkOption {
  #   };
  # };

  config = {
    # the configuration of which specific package set `pkgs.cross` refers to happens elsewhere;
    # here we just define them all.
    nixpkgs.overlays = [
      (next: prev: rec {
        # non-emulated packages build *from* local *for* target.
        # for large packages like the linux kernel which are expensive to build under emulation,
        # the config can explicitly pull such packages from `pkgs.cross` to do more efficient cross-compilation.
        crossFrom."x86_64-linux" = mkCrossFrom "x86_64-linux" prev;
        crossFrom."aarch64-linux" = mkCrossFrom "aarch64-linux" prev;

        emulated = mkEmulated prev;
      })
      (next: prev:
        let
          emulated = prev.emulated;
        in {
          # packages which don't cross compile
          inherit (emulated)
            # adwaita-qt  # psqlodbc
            apacheHttpd  # TODO: not properly patched
            appstream
            blueman
            brltty
            cantarell-fonts  # python3.10-skia-pathops
            colord
            duplicity  # python3.10-s3transfer
            evince
            flakpak
            fuzzel
            fwupd-efi
            fwupd
            gcr
            gmime
            # gnome-keyring
            # gnome-remote-desktop
            gnome-tour
            # gnustep-base  # (used by unar)
            gocryptfs  # gocryptfs-2.3-go-modules
            # grpc
            gst_all_1  # gst_all_1.gst-editing-services
            gupnp
            gupnp_1_6
            gvfs
            flatpak
            hdf5
            http2
            ibus
            kitty
            iio-sensor-proxy
            libHX
            libgweather
            librest
            librest_1_0
            libsForQt5  # qtbase
            mod_dnssd
            ncftp
            obex_data_server
            openfortivpn
            ostree
            pam_mount
            perl  # perl5.36.0-Test-utf8
            pipewire
            psqlodbc
            pulseaudio  # python3.10-defcon
            # qgnomeplatform
            # qtbase
            qt6  # psqlodbc
            rmlint
            sequoia
            # splatmoji
            squeekboard
            sysprof
            tracker-miners  # it just can't run tests
            twitter-color-emoji  # python3.10-defcon
            unar  # python3.10-psycopg2
            visidata  # python3.10-psycopg2
            vpnc
            webp-pixbuf-loader
            xdg-utils  # perl5.36.0-File-BaseDir
          ;
          # pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          #   (py-next: py-prev: {
          #     defcon = py-prev.defcon.override { inherit prev.emulated.stdenv; };
          #     # psycopg2 = py-prev.psycopg2.override { inherit prev.emulated.stdenv; };
          #   })
          # ];

          gnome = prev.gnome.overrideScope' (self: super: {
            inherit (emulated.gnome)
              gnome-color-manager
              gnome-keyring
              gnome-remote-desktop  # TODO: figure out what's asking for this and remove it
              gnome-user-share
              mutter
            ;
          });

          # gst_all_1.gst-editing-services = emulated.gst_all_1.gst-editing-services;

          # gst_all_1 = prev.gst_all_1.overrideScope' (self: super: {
          #   inherit (emulated.gst_all_1)
          #     gst-editing-services
          #   ;
          # });

          # libsForQt5 = prev.libsForQt5.overrideScope' (self: super: {
          #   inherit (emulated.libsForQt5)
          #     qtbase
          #   ;
          # });

          # apacheHttpdPackagesFor = apacheHttpd: self:
          #   let
          #     prevHttpdPkgs = lib.fix (emulated.apacheHttpdPackagesFor apacheHttpd);
          #   in
          #     (prev.apacheHttpdPackagesFor apacheHttpd self) // {
          #       # inherit (prevHttpdPkgs) mod_dnssd;
          #       mod_dnssd = prevHttpdPkgs.mod_dnssd.override {
          #         inherit (self) apacheHttpd;
          #       };
          #     };
      })
    ];

    # perlPackageOverrides = _perl: {
    #   inherit (pkgs.emulated.perl.pkgs)
    #     Testutf8
    #   ;
    # };
  };
}
