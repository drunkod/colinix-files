{ lib, pkgs, ... }:
{
  imports = [
    ./feeds.nix
    ./fs.nix
    ./hardware.nix
    ./home
    ./ids.nix
    ./machine-id.nix
    ./net.nix
    ./nix-path
    ./persist.nix
    ./programs
    ./secrets.nix
    ./ssh.nix
    ./users
    ./vpn.nix
  ];

  sane.nixcache.enable-trusted-keys = true;
  sane.nixcache.enable = lib.mkDefault true;
  sane.persist.enable = lib.mkDefault true;
  sane.programs.sysadminUtils.enableFor.system = lib.mkDefault true;
  sane.programs.consoleUtils.enableFor.user.colin = lib.mkDefault true;

  # some services which use private directories error if the parent (/var/lib/private) isn't 700.
  sane.fs."/var/lib/private".dir.acl.mode = "0700";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = true;  # NIXPKGS_ALLOW_BROKEN

  # time.timeZone = "America/Los_Angeles";
  time.timeZone = "Etc/UTC";  # DST is too confusing for me => use a stable timezone

  # allow `nix flake ...` command
  # TODO: is this still required?
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  # hardlinks identical files in the nix store to save 25-35% disk space.
  # unclear _when_ this occurs. it's not a service.
  # does the daemon continually scan the nix store?
  # does the builder use some content-addressed db to efficiently dedupe?
  nix.settings.auto-optimise-store = true;

  systemd.services.nix-daemon.serviceConfig = {
    # the nix-daemon manages nix builders
    # kill nix-daemon subprocesses when systemd-oomd detects an out-of-memory condition
    # see:
    # - nixos PR that enabled systemd-oomd: <https://github.com/NixOS/nixpkgs/pull/169613>
    # - systemd's docs on these properties: <https://www.freedesktop.org/software/systemd/man/systemd.resource-control.html#ManagedOOMSwap=auto%7Ckill>
    #
    # systemd's docs warn that without swap, systemd-oomd might not be able to react quick enough to save the system.
    # see `man oomd.conf` for further tunables that may help.
    #
    # alternatively, apply this more broadly with `systemd.oomd.enableSystemSlice = true` or `enableRootSlice`
    # TODO: also apply this to the guest user's slice (user-1100.slice)
    # TODO: also apply this to distccd
    ManagedOOMMemoryPressure = "kill";
    ManagedOOMSwap = "kill";
  };

  # TODO: move this to gui machines only
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [ font-awesome noto-fonts-emoji hack-font ];
    fontconfig.enable = true;
    fontconfig.defaultFonts = {
      emoji = [ "Font Awesome 6 Free" "Noto Color Emoji" ];
      monospace = [ "Hack" ];
      serif = [ "DejaVu Serif" ];
      sansSerif = [ "DejaVu Sans" ];
    };
  };

  # XXX: twitter-color-emoji doesn't cross-compile; but not-fonts-emoji does
  # fonts = {
  #   enableDefaultFonts = true;
  #   fonts = with pkgs; [ font-awesome twitter-color-emoji hack-font ];
  #   fontconfig.enable = true;
  #   fontconfig.defaultFonts = {
  #     emoji = [ "Font Awesome 6 Free" "Twitter Color Emoji" ];
  #     monospace = [ "Hack" ];
  #     serif = [ "DejaVu Serif" ];
  #     sansSerif = [ "DejaVu Sans" ];
  #   };
  # };

  # disable non-required packages like nano, perl, rsync, strace
  environment.defaultPackages = [];

  # dconf docs: <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/desktop_migration_and_administration_guide/profiles>
  # find keys/values with `dconf dump /`
  programs.dconf.enable = true;
  programs.dconf.packages = [
    (pkgs.writeTextFile {
      name = "dconf-user-profile";
      destination = "/etc/dconf/profile/user";
      text = ''
        user-db:user
        system-db:site
      '';
    })
  ];

  # link debug symbols into /run/current-system/sw/lib/debug
  # hopefully picked up by gdb automatically?
  environment.enableDebugInfo = true;
}
