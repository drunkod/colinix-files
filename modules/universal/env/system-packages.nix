{ pkgs, ... }:
{
  # general-purpose utilities that we want any user to be able to access
  #   (specifically: root, in case of rescue)
  environment.systemPackages = with pkgs; [
    btrfs-progs
    cryptsetup
    dig
    efibootmgr
    fatresize
    fd
    file
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
    netcat
    nethogs
    nmap
    openssl
    parted
    pciutils
    powertop
    ripgrep
    screen
    smartmontools
    socat
    usbutils
    wget
  ];
}

