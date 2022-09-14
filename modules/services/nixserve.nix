# docs: https://nixos.wiki/wiki/Binary_Cache
# to copy something to this machine's nix cache, do:
#   nix copy --to ssh://nixcache.uninsane.org PACKAGE
{ config, lib, ... }:

with lib;
let
  cfg = config.sane.services.nixserve;
in
{
  options = {
    sane.services.nixserve.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets.nix_serve_privkey.path;
    };

    sops.secrets.nix_serve_privkey = {
      sopsFile = ../../secrets/servo.yaml;
    };
  };
}
