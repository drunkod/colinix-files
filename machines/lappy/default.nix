{ pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  colinsane.gui.sway.enable = true;
  colinsane.impermanence.enable = true;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  colinsane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  # TODO: only here for debugging
  # services.ipfs.enable = true;

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
