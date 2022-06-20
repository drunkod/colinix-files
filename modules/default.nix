{ ... }:

{
  imports = [
    ./gui
    ./hardware
    ./impermanence.nix
    ./services/duplicity.nix
    ./universal
  ];
}
