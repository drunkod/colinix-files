{ lib, pkgs, ... }:

let
  inherit (builtins) attrNames concatLists;
  inherit (lib) mapAttrs mapAttrsToList mkDefault mkMerge;

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

  consolePkgs = {
    inherit (pkgs)
      backblaze-b2
      cdrtools
      dmidecode
      duplicity
      efivar
      flashrom
      fwupd
      ghostscript  # TODO: imagemagick wrapper should add gs to PATH
      gnupg
      gocryptfs
      gopass
      gopass-jsonapi
      ifuse
      imagemagick
      ipfs
      kitty  # TODO: move to GUI, but `ssh servo` from kitty sets `TERM=xterm-kitty` in the remove and breaks things
      libimobiledevice
      libsecret  # for managing user keyrings
      lm_sensors  # for sensors-detect
      lshw
      ffmpeg
      memtester
      networkmanager
      nixpkgs-review
      # nixos-generators
      # nettools
      nmon
      oathToolkit  # for oathtool
      # ponymix
      pulsemixer
      python3
      rsync
      # python3Packages.eyeD3  # music tagging
      sane-scripts
      sequoia
      snapper
      sops
      sox
      speedtest-cli
      sqlite  # to debug sqlite3 databases
      ssh-to-age
      sudo
      # tageditor  # music tagging
      unar
      visidata
      w3m
      wireguard-tools
      # youtube-dl
      yt-dlp
    ;
  };
in
{
  config = {
    sane.programs = mkMerge [
      # define -- but don't enable -- the packages in each group
      # use `mkDefault` for the package here so we can customize some of them further down this file
      (mapAttrs (_n: p: { package = mkDefault p; }) sysadminPkgs)
      (mapAttrs (_n: p: { package = mkDefault p; }) consolePkgs)
      {
        # link the various package sets into their own meta packages
        sysadminUtils = {
          package = null;
          suggestedPrograms = attrNames sysadminPkgs;
        };
        consoleUtils = {
          package = null;
          suggestedPrograms = attrNames consolePkgs;
        };
      }
      {
        # nontrivial package definitions
        imagemagick.package = pkgs.imagemagick.override {
          ghostscriptSupport = true;
        };
      }
    ];

    # XXX: this might not be necessary. try removing this and cacert.unbundled (servo)?
    environment.etc."ssl/certs".source = "${pkgs.cacert.unbundled}/etc/ssl/certs/*";
  };
}
