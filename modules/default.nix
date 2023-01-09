{ lib, utils, ... }:

{
  imports = [
    ./feeds.nix
    ./fs
    ./gui
    ./home-manager
    ./ids.nix
    ./packages.nix
    ./image.nix
    ./nixcache.nix
    ./persist
    ./services
    ./sops.nix
    ./ssh.nix
  ];

  _module.args =  {
    sane-lib = import ./lib { inherit lib utils; };
    sane-data = import ./data;
  };
}
