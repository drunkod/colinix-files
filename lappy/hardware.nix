{ config, pkgs, lib, ... }:

{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.initrd.kernelModules = [ ];
  # find more of these with sensors-detect
  boot.kernelModules = [
    "coretemp"
    "kvm-intel"
    "kvm-amd"  # desktop
    "amdgpu"   # desktop
  ];
  boot.extraModulePackages = [ ];
  boot.kernelParams = [ "boot.shell_on_fail" ];
  boot.consoleLogLevel = 7;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # enable cross compilation
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  powerManagement.cpuFreqGovernor = "powersave";
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;    # desktop
  hardware.cpu.intel.updateMicrocode = true;  # laptop
  powerManagement.powertop.enable = true;
  services.fwupd.enable = true;

  hardware.opengl.extraPackages = [
    # laptop
    pkgs.intel-compute-runtime
    pkgs.intel-media-driver  # new
    pkgs.libvdpau-va-gl      # new
    pkgs.vaapiIntel
    # desktop
    pkgs.rocm-opencl-icd
    pkgs.rocm-opencl-runtime
  ];
  hardware.opengl.driSupport = true;
  # For 32 bit applications
  hardware.opengl.driSupport32Bit = true;


  fileSystems."/" = lib.mkDefault {
    device = "/dev/disk/by-uuid/75230e56-2c69-4e41-b03e-68475f119980";
    fsType = "btrfs";
    options = [
      "compress=zstd"
      "defaults"
    ];
  };

  fileSystems."/boot" = {
    device = lib.mkDefault "/dev/disk/by-uuid/BD79-D6BB";
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
