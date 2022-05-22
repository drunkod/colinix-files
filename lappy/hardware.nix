{ config, pkgs, lib, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  # find more of these with sensors-detect
  boot.kernelModules = [ "coretemp" "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable cross compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  powerManagement.cpuFreqGovernor = "powersave";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = true;
  powerManagement.powertop.enable = true;
  services.fwupd.enable = true;

  hardware.opengl.extraPackages = [
    pkgs.intel-compute-runtime
    pkgs.intel-media-driver  # new
    pkgs.libvdpau-va-gl      # new
    pkgs.vaapiIntel
  ];

  # funky defaulting/forcing here because:
  # - we want to support image generation, where fs is defined by label instead of UUID
  # - we want images to have btrfs roots, not ext4 default
  fileSystems."/" = {
    device = lib.mkDefault "/dev/disk/by-uuid/75230e56-2c69-4e41-b03e-68475f119980";
    fsType = lib.mkForce "btrfs";
    options = lib.mkDefault [
      "compress=zstd"
      "defaults"
    ];
    autoResize = lib.mkForce false;
  };

  fileSystems."/boot" = lib.mkDefault {
    device = "/dev/disk/by-uuid/BD79-D6BB";
    fsType = "vfat";
  };

  swapDevices = [ ];

  time.timeZone = "America/Los_Angeles";

  # start gnome/gdm on boot
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  # services.snapper.configs = {
  #   root = {
  #     subvolume = "/";
  #     extraConfig = {
  #       ALLOW_USERS = "colin";
  #     };
  #   };
  # };
  # services.snapper.snapshotInterval = "daily";

  networking.useDHCP = false;
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

}
