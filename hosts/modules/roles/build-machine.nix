{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;
in
{
  options.sane.roles.build-machine = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf config.sane.roles.build-machine {
    # serve packages to other machines that ask for them
    sane.services.nixserve.enable = true;

    # enable cross compilation
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    # nixpkgs.config.allowUnsupportedSystem = true;
  };
}
