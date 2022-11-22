{ ... }:
{
  imports = [
    ./hardware
    ./secrets.nix
  ];

  sane.nixcache.enable-trusted-keys = true;

  nixpkgs.config.allowUnfree = true;
}
