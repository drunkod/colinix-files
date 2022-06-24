{ pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  colinsane.home-manager.extraPackages = [
    pkgs.electron
  ];
  colinsane.gui.sway.enable = true;
  colinsane.services.duplicity.enable = true;
  colinsane.impermanence.enable = true;

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  colinsane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  # needed to use libimobiledevice/ifuse, for iphone sync
  services.usbmuxd.enable = true;

  sops.secrets.duplicity_passphrase = {
    sopsFile = ../../secrets/desko.yaml;
  };

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
