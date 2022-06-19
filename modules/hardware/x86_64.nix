{ lib, pkgs, config, ... }:

with lib;
{
  config = mkIf (pkgs.system == "x86_64-linux") { 
    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "sd_mod" "sdhci_pci"  # nixos-generate-config defaults
      "usb_storage"   # rpi needed this to boot from usb storage, i think.
      # "usbhid" "hid-generic"  # hopefully these will fix USB HID auto-sleep ?
    ];
    boot.initrd.kernelModules = [ ];
    boot.initrd.supportedFilesystems = [ "ext4" "btrfs" "ext2" "ext3" "vfat" ];
    # useful emergency utils
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.btrfs-progs}/bin/btrfstune
    '';
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
    boot.loader.systemd-boot.configurationLimit = 40;  # keep this many generations
    boot.loader.efi.canTouchEfiVariables = true;

    # enable cross compilation
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    # nixpkgs.crossSystem.system = "aarch64-linux";

    powerManagement.cpuFreqGovernor = "powersave";
    hardware.enableRedistributableFirmware = true;
    hardware.cpu.amd.updateMicrocode = true;    # desktop
    hardware.cpu.intel.updateMicrocode = true;  # laptop
    services.fwupd.enable = true;
    # powertop will default to putting USB devices -- including HID -- to sleep after TWO SECONDS
    powerManagement.powertop.enable = false;

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

    # TODO colin: does this *do* anything?
    swapDevices = [ ];

    # services.snapper.configs = {
    #   root = {
    #     subvolume = "/";
    #     extraConfig = {
    #       ALLOW_USERS = "colin";
    #     };
    #   };
    # };
    # services.snapper.snapshotInterval = "daily";
  };
}
