{ pkgs, ... }:
{
  imports = [
    ./fs.nix
  ];

  colinsane.home-manager.extraPackages = [
    pkgs.electrum
  ];
  colinsane.gui.sway.enable = true;
  colinsane.services.duplicity.enable = true;
  colinsane.impermanence.enable = true;

  boot.loader.generic-extlinux-compatible.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  colinsane.image.extraBootFiles = [ pkgs.bootpart-uefi-x86_64 ];

  hardware.opengl.extraPackages = with pkgs; [
    rocm-opencl-icd
    rocm-opencl-runtime
    amdvlk
  ];

  # needed to use libimobiledevice/ifuse, for iphone sync
  services.usbmuxd.enable = true;

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

  # docs: https://nixos.org/manual/nixos/stable/options.html#opt-system.stateVersion
  system.stateVersion = "21.05";
}
