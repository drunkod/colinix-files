{ config, ... }:

let
  mkCrossFrom = localSystem: pkgs: import pkgs.path {
    inherit localSystem;
    crossSystem = pkgs.stdenv.hostPlatform.system;
    inherit (config.nixpkgs) config overlays;
  };
in
{
  # the configuration of which specific package set `pkgs.cross` refers to happens elsewhere;
  # here we just define them all.
  nixpkgs.overlays = [
    (next: prev: {
      # non-emulated packages build *from* local *for* target.
      # for large packages like the linux kernel which are expensive to build under emulation,
      # the config can explicitly pull such packages from `pkgs.cross` to do more efficient cross-compilation.
      crossFrom."x86_64-linux" = mkCrossFrom "x86_64-linux" next;
      crossFrom."aarch64-linux" = mkCrossFrom "aarch64-linux" next;
    })
  ];
}
