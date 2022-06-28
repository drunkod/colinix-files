{ ... }:

{
  imports = [
    ./gui
    ./hardware
    ./image.nix
    ./impermanence.nix
    ./nix.nix
    ./services/duplicity.nix
    ./universal
  ];
}
