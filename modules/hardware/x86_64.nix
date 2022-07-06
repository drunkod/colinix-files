{ lib, pkgs, config, ... }:

with lib;
{
  config = mkIf (pkgs.system == "x86_64-linux") { 
    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "sd_mod" "sdhci_pci"  # nixos-generate-config defaults
      "usb_storage"   # rpi needed this to boot from usb storage, i think.
      "nvme"  # to boot from nvme devices
      # efi_pstore evivars
    ];
    boot.initrd.kernelModules = [ ];
    boot.initrd.supportedFilesystems = [ "ext4" "btrfs" "ext2" "ext3" "vfat" ];
    # useful emergency utils
    boot.initrd.extraUtilsCommands = ''
      copy_bin_and_libs ${pkgs.btrfs-progs}/bin/btrfstune
    '';
    boot.extraModulePackages = [ ];
    boot.kernelParams = [ "boot.shell_on_fail" ];
    boot.consoleLogLevel = 7;

    boot.loader.grub.enable = false;
    # boot.loader.generic-extlinux-compatible.enable = true;

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

    hardware.opengl.driSupport = true;
    # For 32 bit applications
    hardware.opengl.driSupport32Bit = true;

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
