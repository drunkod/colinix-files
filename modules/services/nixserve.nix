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
    sane.services.nixserve.sopsFile = mkOption {
      default = ../../secrets/servo.yaml;
      type = types.path;
    };
  };

  config = mkIf cfg.enable {
    services.nix-serve = {
      enable = true;
      secretKeyFile = config.sops.secrets.nix_serve_privkey.path;
      openFirewall = true;  # not needed for servo; only desko
    };

    sops.secrets.nix_serve_privkey = {
      sopsFile = cfg.sopsFile;
    };
  };
}
