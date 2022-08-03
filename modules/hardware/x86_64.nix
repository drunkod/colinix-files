{ lib, pkgs, ... }:

with lib;
{
  # TODO: some of this might generalize beyond just x86
  config = mkIf (pkgs.system == "x86_64-linux") { 
    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "sd_mod" "sdhci_pci"  # nixos-generate-config defaults
      "usb_storage"   # rpi needed this to boot from usb storage, i think.
      "nvme"  # to boot from nvme devices
      # efi_pstore evivars
    ];
    boot.initrd.kernelModules = [ ];
    boot.extraModulePackages = [ ];

    # enable cross compilation
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
    # nixpkgs.crossSystem.system = "aarch64-linux";

    powerManagement.cpuFreqGovernor = "powersave";
    hardware.cpu.amd.updateMicrocode = true;    # desktop
    hardware.cpu.intel.updateMicrocode = true;  # laptop

    hardware.opengl.driSupport = true;
    # For 32 bit applications
    hardware.opengl.driSupport32Bit = true;
  };
}
