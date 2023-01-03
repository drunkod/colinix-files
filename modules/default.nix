{ ... }:

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
}
