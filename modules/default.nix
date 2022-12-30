{ ... }:

{
  imports = [
    ./allocations.nix
    ./fs.nix
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
