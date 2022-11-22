{ ... }:
{
  imports = [
    ./fs.nix
    ./hardware
    ./machine-id.nix
    ./net.nix
    ./secrets.nix
    ./ssh.nix
    ./users.nix
    ./vpn.nix
  ];

  sane.nixcache.enable-trusted-keys = true;
  sane.packages.enableConsolePkgs = true;
  sane.packages.enableSystemPkgs = true;

  nixpkgs.config.allowUnfree = true;
}
