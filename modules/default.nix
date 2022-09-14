{ ... }:

{
  imports = [
    ./gui
    ./hardware
    ./image.nix
    ./impermanence.nix
    ./nixcache.nix
    ./services/duplicity.nix
    ./services/nixserve.nix
    ./universal
  ];
}
