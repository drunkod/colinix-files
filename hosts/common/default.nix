{ ... }:
{
  imports = [
    ./hardware
    ./secrets.nix
    ./vpn.nix
  ];

  sane.nixcache.enable-trusted-keys = true;

  nixpkgs.config.allowUnfree = true;
}
