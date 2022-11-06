# speed up builds from e.g. moby or lappy by having them query desko and servo first.
# if one of these hosts is offline, instead manually specify just cachix:
# - `nixos-rebuild --option substituters https://cache.nixos.org/`
#
# future improvements:
# - apply for community arm build box:
#   - <https://github.com/nix-community/aarch64-build-box>
# - don't require all substituters to be online:
#   - <https://github.com/NixOS/nix/pull/7188>

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

  config = {
    # use our own binary cache
    # to explicitly build from a specific cache (in case others are down):
    # - `nixos-rebuild ... --option substituters https://cache.nixos.org`
    # - `nix build ... --substituters http://desko:5000`
    nix.settings.substituters = mkIf cfg.enable [
      "https://nixcache.uninsane.org"
      "http://desko:5000"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    # always trust our keys (so one can explicitly use a substituter even if it's not the default
    nix.settings.trusted-public-keys = [
      "nixcache.uninsane.org:r3WILM6+QrkmsLgqVQcEdibFD7Q/4gyzD9dGT33GP70="
      "desko:Q7mjjqoBMgNQ5P0e63sLur65A+D4f3Sv4QiycDIKxiI="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
