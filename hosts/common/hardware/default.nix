{ lib, pkgs, ... }:

{
  imports = [
    ./x86_64.nix
  ];

  boot.initrd.supportedFilesystems = [ "ext4" "btrfs" "ext2" "ext3" "vfat" ];
  # useful emergency utils
  boot.initrd.extraUtilsCommands = ''
    copy_bin_and_libs ${pkgs.btrfs-progs}/bin/btrfstune
  '';
  boot.kernelParams = [ "boot.shell_on_fail" ];
  # other kernelParams:
  #   "boot.trace"
  #   "systemd.log_level=debug"
  #   "systemd.log_target=console"

  # TODO: remove once it no longer applies
  # this fixes /mnt/servo-nfs mount failures
  # <https://github.com/NixOS/nixpkgs/issues/255803>
  boot.kernelPatches = [{
    name = "backport-nfs4-selinux-fix";
    patch = pkgs.fetchpatch {
      url = "https://patchwork.kernel.org/project/selinux/patch/20230911142358.883728-1-omosnace@redhat.com/raw/";
      hash = "sha256-m947t39xr4VqJBZ2mYTFq9Up/NWlwueH8aXFZRQwA7c=";
    };
  }];

  # hack in the `boot.shell_on_fail` arg since that doesn't always seem to work.
  boot.initrd.preFailCommands = "allowShell=1";

  # default: 4 (warn). 7 is debug
  boot.consoleLogLevel = 7;

  boot.loader.grub.enable = lib.mkDefault false;
  boot.loader.generic-extlinux-compatible.enable = lib.mkDefault true;

  # non-free firmware
  hardware.enableRedistributableFirmware = true;

  # powertop will default to putting USB devices -- including HID -- to sleep after TWO SECONDS
  powerManagement.powertop.enable = false;
  # linux CPU governor: <https://www.kernel.org/doc/Documentation/cpu-freq/governors.txt>
  # - options:
  #   - "powersave" => force CPU to always run at lowest supported frequency
  #   - "performance" => force CPU to always run at highest frequency
  #   - "ondemand" => adjust frequency based on load
  #   - "conservative"  (ondemand but slower to adjust)
  #   - "schedutil"
  #   - "userspace"
  # - not all options are available for all platforms
  #   - intel (intel_pstate) appears to manage scaling w/o intervention/control from the OS.
  #   - AMD (acpi-cpufreq) appears to manage scaling via the OS *or* HW. but the ondemand defaults never put it to max hardware frequency.
  #   - qualcomm (cpufreq-dt) appears to manage scaling *only* via the OS. ondemand governor exercises the full range.
  # - query details with `sudo cpupower frequency-info`
  powerManagement.cpuFreqGovernor = "ondemand";

  services.logind.extraConfig = ''
    # don’t shutdown when power button is short-pressed
    HandlePowerKey=ignore
  '';

  # services.snapper.configs = {
  #   root = {
  #     subvolume = "/";
  #     extraConfig = {
  #       ALLOW_USERS = "colin";
  #     };
  #   };
  # };
  # services.snapper.snapshotInterval = "daily";
}
