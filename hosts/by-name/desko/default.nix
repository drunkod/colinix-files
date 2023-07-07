{ config, pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  sane.guest.enable = true;

  # TODO: make sure this plays nice with impermanence
  services.distccd.enable = true;
  sane.programs.distcc.enableFor.user.guest = true;

  sops.secrets.colin-passwd.neededForUsers = true;

  sane.roles.build-machine.enable = true;
  sane.roles.ac = true;
  sane.roles.client = true;
  sane.roles.dev-machine = true;
  sane.services.wg-home.enable = true;
  sane.services.wg-home.ip = config.sane.hosts.by-name."desko".wg-home.ip;
  sane.services.duplicity.enable = true;
  sane.services.nixserve.secretKeyFile = config.sops.secrets.nix_serve_privkey.path;

  sane.gui.sway.enable = true;
  sane.programs.iphoneUtils.enableFor.user.colin = true;

  sane.programs.guiApps.suggestedPrograms = [ "desktopGuiApps" ];
  sane.programs.consoleUtils.suggestedPrograms = [ "consoleMediaUtils" ];
  # sane.programs.devPkgs.enableFor.user.colin = true;

  boot.loader.efi.canTouchEfiVariables = false;
  sane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  # needed to use libimobiledevice/ifuse, for iphone sync
  services.usbmuxd.enable = true;

  # don't enable wifi by default: it messes with connectivity.
  systemd.services.iwd.enable = false;

  # default config: https://man.archlinux.org/man/snapper-configs.5
  # defaults to something like:
  #   - hourly snapshots
  #   - auto cleanup; keep the last 10 hourlies, last 10 daylies, last 10 monthlys.
  services.snapper.configs.nix = {
    # TODO: for the impermanent setup, we'd prefer to just do /nix/persist,
    # but that also requires setting up the persist dir as a subvol
    SUBVOLUME = "/nix";
    # TODO: ALLOW_USERS doesn't seem to work. still need `sudo snapper -c nix list`
    ALLOW_USERS = [ "colin" ];
  };

  programs.steam = {
    enable = true;
    # not sure if needed: stole this whole snippet from the wiki
    remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
  };
  sane.user.persist.plaintext = [
    ".steam"
    ".local/share/Steam"
  ];

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
