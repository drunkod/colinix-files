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

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/75230e56-2c69-4e41-b03e-68475f119980";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/BD79-D6BB";
      fsType = "vfat";
    };

  swapDevices = [ ];

  time.timeZone = "America/Los_Angeles";

  # start gnome/gdm on boot
  services.xserver.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.displayManager.gdm.enable = true;

  networking.useDHCP = false;
  networking.networkmanager.enable = true;

}
