{ ... }:

{
  imports = [
    ./allocations.nix
    ./gui
    ./home-manager
    ./packages.nix
    ./image.nix
    ./impermanence
    ./nixcache.nix
    ./services
  ];
}
