{ ... }:

{
  imports = [
    ./allocations.nix
    ./gui
    ./home-manager
    ./packages.nix
    ./image.nix
    ./impermanence.nix
    ./nixcache.nix
    ./services
  ];
}
