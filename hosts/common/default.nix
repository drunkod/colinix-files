{ ... }:
{
  imports = [
    ./fs.nix
    ./hardware
    ./machine-id.nix
    ./net.nix
    ./secrets.nix
    ./ssh.nix
    ./system-packages.nix
    ./users.nix
    ./vpn.nix
  ];

  sane.nixcache.enable-trusted-keys = true;

  nixpkgs.config.allowUnfree = true;
}
