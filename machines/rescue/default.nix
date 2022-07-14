{ pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  colinsane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  # TODO: enable root login via ssh

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
