{ pkgs, ... }:

{
  imports = [
    ./fs.nix
    ./hardware.nix
    ./net.nix
    ./users.nix
    ./services
  ];

  sane.home-manager.extraPackages = [
    # for administering services
    pkgs.matrix-synapse
    pkgs.freshrss
    pkgs.goaccess
  ];
  sane.impermanence.enable = true;
  sane.services.duplicity.enable = true;
  sane.services.nixserve.enable = true;

  # TODO: look into the EFI stuff
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  sane.image.extraBootFiles = [ pkgs.bootpart-u-boot-rpi-aarch64 ];

  sops.secrets.duplicity_passphrase = {
    sopsFile = ../../secrets/servo.yaml;
  };

  # both transmission and ipfs try to set different net defaults.
  # we just use the most aggressive of the two here:
  boot.kernel.sysctl = {
    "net.core.rmem_max" = 4194304;  # 4MB
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?
}

