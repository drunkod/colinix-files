{ lib, config, ... }:

with lib;
let
  cfg = config.sane.nixcache;
in
{
  options = {
    sane.nixcache.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    # use our own binary cache
    nix.settings = {
      substituters = [
        "https://nixcache.uninsane.org"
        "http://desko:5000"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "nixcache.uninsane.org:r3WILM6+QrkmsLgqVQcEdibFD7Q/4gyzD9dGT33GP70="
        "desko:Q7mjjqoBMgNQ5P0e63sLur65A+D4f3Sv4QiycDIKxiI="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };
  };
}
