{ ... }:

{
  imports = [
    ./gui
    ./hardware
    ./image.nix
    ./impermanence.nix
    ./services/duplicity.nix
    ./universal
  ];
}
