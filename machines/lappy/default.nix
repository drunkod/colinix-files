{ ... }:
{
  imports = [
    ./fs.nix
  ];

  # colinsane.gui.sway.enable = true;
  # colinsane.impermanence.enable = true;
  colinsane.extlinux.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
