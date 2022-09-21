{ config, lib, pkgs, ... }:

with lib;
with pkgs;
let
  cfg = config.sane.home-packages;
  universalPkgs = [
    backblaze-b2
    duplicity
    gnupg
    ifuse
    ipfs
    libimobiledevice
    lm_sensors  # for sensors-detect
    lshw
    ffmpeg
    nb
    networkmanager
    nixpkgs-review
    # nixos-generators
    # nettools
    nmon
    oathToolkit  # for oathtool
    # ponymix
    pulsemixer
    python3
    rmlint
    sane-scripts
    sequoia
    snapper
    sops
    speedtest-cli
    ssh-to-age
    sudo
    unar
    visidata
    w3m
    wireguard-tools
    # youtube-dl
    yt-dlp
  ];

  guiPkgs = [
    # GUI only
    aerc  # email client
    audacity
    chromium
    clinfo
    electrum

    # creds/session keys, etc
    { pkg = element-desktop; dir = ".config/Element"; }

    emote  # TODO: package [smile](https://github.com/mijorus/smile) for probably a better mobile experience.
    evince  # works on phosh
    fluffychat
    foliate
    font-manager
    gimp  # broken on phosh
    gnome.cheese
    gnome.dconf-editor
    gnome-feeds  # RSS reader (with claimed mobile support)
    gnome.file-roller
    gnome.gnome-disk-utility
    gnome.gnome-maps  # works on phosh
    gnome.nautilus
    gnome-podcasts
    gnome.gnome-system-monitor
    gnome.gnome-terminal  # works on phosh
    gthumb
    inkscape
    krita
    libreoffice-fresh  # XXX colin: maybe don't want this on mobile
    lollypop
    mesa-demos
    networkmanagerapplet

    # settings (electron app). TODO: can i manage these settings with home-manager?
    { pkg = obsidian; dir = ".config/obsidian"; }

    pavucontrol
    playerctl
    soundconverter
    # sublime music persists any downloaded albums here.
    # it doesn't obey a conventional ~/Music/{Artist}/{Album}/{Track} notation, so no symlinking
    # config (e.g. server connection details) is persisted in ~/.config/sublime-music/config.json
    #   possible to pass config as a CLI arg (sublime-music -c config.json)
    { pkg = sublime-music; dir = ".local/share/sublime-music"; }
    tdesktop  # broken on phosh
    vlc  # works on phosh
    whalebird # pleroma client. input is broken on phosh
    xterm  # broken on phosh
  ]
  ++ (if pkgs.system == "x86_64-linux" then
  [
    # x86_64 only

    # creds, but also 200 MB of node modules, etc
    (let discord = (pkgs.discord.override {
      # XXX 2022-07-31: fix to allow links to open in default web-browser:
      #   https://github.com/NixOS/nixpkgs/issues/78961
      nss = pkgs.nss_latest;
    }); in { pkg = discord; dir = ".config/discord"; })

    # kaiteki  # Pleroma client
    # gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)

    logseq
    losslesscut-bin
    makemkv

    # actual monero blockchain (not wallet/etc; safe to delete, just slow to regenerate)
    { pkg = monero-gui; dir = ".bitmonero"; }

    # creds, media
    { pkg = signal-desktop; dir = ".config/Signal"; }

    # creds. TODO: can i manage this with home-manager?
    { pkg = spotify; dir = ".config/spotify"; }

    # hardenedMalloc solves a crash at startup
    (tor-browser-bundle-bin.override { useHardenedMalloc = false; })

    # zcash coins. safe to delete, just slow to regenerate (10-60 minutes)
    { pkg = zecwallet-lite; dir = ".zcash"; }
  ] else []);

  # useful devtools:
  # bison
  # dtc
  # flex
  # gcc
  # gcc-arm-embedded
  # gcc_multi
  # gnumake
  # mix2nix
  # rustup
  # swig
in
{
  options = {
    sane.home-packages.enableGuiPkgs = mkOption {
      default = false;
      type = types.bool;
    };
  };
  config = {
    sane.home-manager.extraPackages = universalPkgs
      ++ (if cfg.enableGuiPkgs then guiPkgs else []);
  };
}
