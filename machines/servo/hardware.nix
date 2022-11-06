# this file originates from ‘nixos-generate-config’
# but has been heavily modified
{ pkgs, ... }:

{
  # i changed this becuse linux 5.10 didn't have rpi-400 device tree blob.
  # nixos-22.05 linux 5.15 DOES have these now.
  # it should be possible to remove this if desired, but i'm not sure how the rpi-specific kernel differs.
  # see: https://github.com/raspberrypi/linux
  boot.kernelPackages = pkgs.cross.linuxPackages_rpi4;

  # raspberryPi boot loader creates extlinux.conf.
  #   otherwise, enable the generic-extlinux-compatible loader below.
  # note: THESE ARE MUTUALLY EXCLUSIVE. generic-extlinux-compatible causes uboot to not be built

  boot.initrd.availableKernelModules = [
    "bcm2711_thermal"
    "bcm_phy_lib"
    "brcmfmac"
    "brcmutil"
    "broadcom"
    "clk_raspberrypi"
    "drm"  # Direct Render Manager
    "enclosure"  # SCSI ?
    "fuse"
    "mdio_bcm_unimac"
    "pcie_brcmstb"
    "raspberrypi_cpufreq"
    "raspberrypi_hwmon"
    "ses"  # SCSI Enclosure Services
    "uas"  # USB attached storage
    "uio"  # userspace IO
    "uio_pdrv_genirq"
    "xhci_pci"
    "xhci_pci_renesas"
  ];
  # boot.initrd.compressor = "gzip";  # defaults to zstd

  # ondemand power scaling keeps the cpu at low frequency when idle, and sets to max frequency
  # when load is detected. (v.s. the "performance" default, which always uses the max frequency)
  powerManagement.cpuFreqGovernor = "ondemand";

  # XXX colin: this allows one to `systemctl halt` and then not remove power until the HDD has spun down.
  # however, it doesn't work with reboot because systemd will spin the drive up again to read its reboot bin.
  # a better solution would be to put the drive behind a powered USB hub (or get a SSD).
  # systemd.services.diskguard = {
  #   description = "Safely power off spinning media";
  #   before = [ "shutdown.target" ];
  #   wantedBy = [ "sysinit.target" ];
  #   # old (creates dep loop, but works)
  #   # before = [ "systemd-remount-fs.service" "shutdown.target" ];
  #   # wantedBy = [ "systemd-remount-fs.service" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #     ExecStart = "${pkgs.coreutils}/bin/true";
  #     ExecStop = with pkgs; writeScript "diskguard" ''
  #       #!${bash}/bin/bash
  #       if ${procps}/bin/pgrep nixos-rebuild ;
  #       then
  #         exit 0  # don't halt drives unless we're actually shutting down. maybe better way to do this (check script args?)
  #       fi
  #       # ${coreutils}/bin/sync
  #       # ${util-linux}/bin/mount -o remount,ro /nix/store
  #       # ${util-linux}/bin/mount -o remount,ro /
  #       # -S 1 retracts the spindle after 5 seconds of idle
  #       # -B 1 spins down the drive after <vendor specific duration>
  #       ${hdparm}/sbin/hdparm -S 1 -B 1 /dev/sda
  #       # TODO: monitor smartmonctl until disk is idle? or try hdparm -Y
  #       # ${coreutils}/bin/sleep 20
  #       # exec ${util-linux}/bin/umount --all -t ext4,vfat,ext2
  #     '';
  #   };
  # };
}
