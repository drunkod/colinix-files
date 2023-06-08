{ lib, ... }:

{
  imports = [
    ./dns.nix
    ./feeds.nix
    ./fs
    ./ids.nix
    ./programs.nix
    ./image.nix
    ./persist
    ./ports.nix
    ./services
    ./sops.nix
    ./ssh.nix
    ./users.nix
  ];

  _module.args =  rec {
    sane-lib = import ./lib { inherit lib; };
    sane-data = import ./data { inherit lib sane-lib; };
  };
}
