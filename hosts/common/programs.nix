{ lib, pkgs, sane-lib, ... }:

let
  inherit (builtins) concatLists;
  inherit (lib) mapAttrsToList;
  systemPkgs = {
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

  enableSysPkg = pname: pkg: {
    sane.programs."${pname}" = {
      package = pkg;
      enableFor.system = true;
    };
  };

  configs = concatLists [
    (mapAttrsToList enableSysPkg systemPkgs)
    [{
      # XXX: this might not be necessary. try removing this and cacert.unbundled (servo)?
      environment.etc."ssl/certs".source = "${pkgs.cacert.unbundled}/etc/ssl/certs/*";
    }]
  ];
in
{
  config =
    let
      take = f: {
        sane.programs = f.sane.programs;
        environment.etc = f.environment.etc;
      };
    in
      take (sane-lib.mkTypedMerge take configs);
}
