{ config, pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  sane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  users.users.dhcpcd.uid = config.sane.allocations.dhcpcd-uid;
  users.groups.dhcpcd.gid = config.sane.allocations.dhcpcd-gid;

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
