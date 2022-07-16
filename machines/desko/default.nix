{ config, pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  colinsane.gui.sway.enable = true;
  colinsane.services.duplicity.enable = true;
  colinsane.impermanence.enable = true;

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  colinsane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  # needed to use libimobiledevice/ifuse, for iphone sync
  services.usbmuxd.enable = true;
  users.users.usbmux.uid = config.colinsane.allocations.usbmux-uid;
  users.groups.usbmux.gid = config.colinsane.allocations.usbmux-gid;

  # default config: https://man.archlinux.org/man/snapper-configs.5
  # defaults to something like:
  #   - hourly snapshots
  #   - auto cleanup; keep the last 10 hourlies, last 10 daylies, last 10 monthlys.
  services.snapper.configs.nix = {
    # TODO: for the impermanent setup, we'd prefer to just do /nix/persist,
    # but that also requires setting up the persist dir as a subvol
    subvolume = "/nix";
    # TODO: ALLOW_USERS doesn't seem to work. still need `sudo snapper -c nix list`
    extraConfig = ''
      ALLOW_USERS = "colin";
    '';
  };

  sops.secrets.duplicity_passphrase = {
    sopsFile = ../../secrets/desko.yaml;
  };

  programs.steam = {
    enable = true;
    # not sure if needed: stole this whole snippet from the wiki
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
  colinsane.impermanence.home-dirs = [
    ".steam"
    ".local/share/Steam"
  ];

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
