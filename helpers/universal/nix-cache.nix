{ ... }:

{
  # use our own binary cache
  nix.settings = {
    substituters = [
      "https://nixcache.uninsane.org"
      "https://nix-community.cachix.org"
      "https://cache.nixos.org/"
    ];
    trusted-public-keys = [
      "nixcache.uninsane.org:r3WILM6+QrkmsLgqVQcEdibFD7Q/4gyzD9dGT33GP70="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
}
