{ config, ... }:

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
    (next: prev: {
      # packages which don't cross compile
      inherit (prev.emulated)
        duplicity  # python3.10-s3transfer
        fuzzel
        fwupd-efi
        fwupd
        # gnustep-base  # (used by unar)
        gocryptfs  # gocryptfs-2.3-go-modules
        # grpc
        hdf5
        http2
        kitty
        iio-sensor-proxy
        libHX
        pam_mount
        pipewire
        ncftp
        rmlint
        sequoia
        # splatmoji
        twitter-color-emoji  # python3.10-defcon
        unar  # python3.10-psycopg2
        visidata  # python3.10-psycopg2
        xdg-utils  # perl5.36.0-File-BaseDir
      ;
      # pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      #   (py-next: py-prev: {
      #     defcon = py-prev.defcon.override { inherit prev.emulated.stdenv; };
      #     # psycopg2 = py-prev.psycopg2.override { inherit prev.emulated.stdenv; };
      #   })
      # ];
    })
  ];
}
