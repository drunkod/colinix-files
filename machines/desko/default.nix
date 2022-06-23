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

  # needed to use libimobiledevice/ifuse, for iphone sync
  services.usbmuxd.enable = true;

  sops.secrets.duplicity_passphrase = {
    sopsFile = ../../secrets/desko.yaml;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 40;  # keep this many generations
  boot.loader.efi.canTouchEfiVariables = true;

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
