{ lib, utils, ... }:

{
  imports = [
    ./feeds.nix
    ./fs
    ./ids.nix
    ./packages.nix
    ./programs.nix
    ./image.nix
    ./persist
    ./services
    ./sops.nix
    ./ssh.nix
    ./users.nix
  ];

  _module.args =  {
    sane-lib = import ./lib { inherit lib utils; };
    sane-data = import ./data { inherit lib; };
  };
}
