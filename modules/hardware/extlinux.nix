{ lib, pkgs, config, nixpkgs, ... }:

with lib;
let
  cfg = config.colinsane.extlinux;
  genericBuilder = (import "${nixpkgs}/nixos/modules/system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix" { inherit pkgs; });
  builder = pkgs.substituteAll {
    src = ./extlinux-builder.sh;
    isExecutable = true;
    inherit (pkgs) bash syslinux;
    inherit genericBuilder;
  };
in
{
  options = {
    colinsane.extlinux.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    # XXX: i'm not 100% sure this is true. i saw some errors related to reading EFI vars though.
    boot.loader.efi.canTouchEfiVariables = false;
    system.build.installBootLoader = let
      dtCfg = config.hardware.deviceTree;
      builderArgs = "-g 20 -t 5"
        + lib.optionalString (dtCfg.name != null) "-n ${dtCfg.name}";

    in "${builder} ${builderArgs} -c";
    system.boot.loader.id = "extlinux";
  };

  # i'm not sure why the below doesn't work instead??
  # config = mkIf cfg.enable {
  #   system.build.installBootLoader =
  #   let
  #     generic-install = (import "${nixpkgs}/nixos/modules/system/boot/loader/generic-extlinux-compatible/default.nix" {
  #       inherit lib pkgs;
  #       config = config // {
  #         boot.loader.generic-extlinux-compatible.enable = true;
  #       };
  #     });
  #   in generic-install.config.system.build.installBootLoader;
  #   system.boot.loader.id = "extlinux";
  # };
}
