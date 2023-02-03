{ lib, pkgs, ... }:

let
  inherit (builtins) attrNames concatLists;
  inherit (lib) mapAttrsToList mkMerge;
  sysadminPkgs = {
    inherit (pkgs // {
      # XXX can't `inherit` a nested attr, so we move them to the toplevel
      "cacert.unbundled" = pkgs.cacert.unbundled;
    })
      btrfs-progs
      "cacert.unbundled"  # some services require unbundled /etc/ssl/certs
      cryptsetup
      dig
      efibootmgr
      fatresize
      fd
      file
      gawk
      git
      gptfdisk
      hdparm
      htop
      iftop
      inetutils  # for telnet
      iotop
      iptables
      jq
      killall
      lsof
      nano
      netcat
      nethogs
      nmap
      openssl
      parted
      pciutils
      powertop
      pstree
      ripgrep
      screen
      smartmontools
      socat
      strace
      tcpdump
      tree
      usbutils
      wget
    ;
  };
in
{
  config = mkMerge [
    {
      # define -- but don't enable -- the system packages
      sane.programs = sysadminPkgs;
    }
    {
      # link the system packages into a meta package
      sane.programs.sysadminUtils = {
        package = null;  # meta package
        suggestedPrograms = attrNames sysadminPkgs;
      };
    }
    {
      # XXX: this might not be necessary. try removing this and cacert.unbundled (servo)?
      environment.etc."ssl/certs".source = "${pkgs.cacert.unbundled}/etc/ssl/certs/*";
    }
  ];
}
