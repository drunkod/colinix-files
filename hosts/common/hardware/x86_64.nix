{ lib, pkgs, ... }:

{
  config = lib.mkIf (pkgs.system == "x86_64-linux") {
    boot.initrd.availableKernelModules = [
      "xhci_pci" "ahci" "sd_mod" "sdhci_pci"  # nixos-generate-config defaults
      "usb_storage"   # rpi needed this to boot from usb storage, i think.
      "nvme"  # to boot from nvme devices
      # efi_pstore evivars
    ];
    # moby has to run recent kernels (defined elsewhere).
    # meanwhile, kernel variation plays some minor role in things like sandboxing (landlock) and capabilities.
    # simpler to keep near the latest kernel on all devices,
    # and also makes certain that any weird system-level bugs i see aren't likely to be stale kernel bugs.
    boot.kernelPackages = lib.mkDefault (pkgs.linuxPackagesFor pkgs.linux_latest);

    hardware.cpu.amd.updateMicrocode = true;    # desktop
    hardware.cpu.intel.updateMicrocode = true;  # laptop
  };
}
