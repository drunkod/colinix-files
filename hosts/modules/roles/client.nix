{ config, lib, ... }:

let
  inherit (lib) mkIf mkOption types;
in
{
  options.sane.roles.client = mkOption {
    type = types.bool;
    default = false;
  };

  config = mkIf config.sane.roles.client {
    sane.services.wg-home.enable = true;
    sane.services.wg-home.role = "client";
  };
}
