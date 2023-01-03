{ lib, utils, ... }:

{
  imports = [
    ./allocations.nix
    ./fs
    ./gui
    ./home-manager
    ./packages.nix
    ./image.nix
    ./impermanence
    ./nixcache.nix
    ./services
    ./sops.nix
  ];

  _module.args =  {
    sane-lib = import ./lib { inherit lib utils; };
  };
}
