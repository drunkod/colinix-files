{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.sane.home-manager;
in
{
  options = {
    sane.home-manager.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };
}
