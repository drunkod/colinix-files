{ ... }:
{
  imports = [
    ./hardware
  ];

  sane.nixcache.enable-trusted-keys = true;

  nixpkgs.config.allowUnfree = true;
}
