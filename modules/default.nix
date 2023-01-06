{ lib, utils, ... }:

{
  imports = [
    ./allocations.nix
    ./fs
    ./gui
    ./home-manager
    ./packages.nix
    ./image.nix
    ./nixcache.nix
    ./persist
    ./services
    ./sops.nix
  ];

  _module.args =  {
    sane-lib = import ./lib { inherit lib utils; };
  };
}
