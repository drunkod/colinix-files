{ config, lib, pkgs, ... }:

with pkgs;
let
  pkgspec = [
    backblaze-b2
    duplicity
    gnupg
    ifuse
    ipfs
    libimobiledevice
    lm_sensors  # for sensors-detect
    nb
    networkmanager
    nixpkgs-review
    # nixos-generators
    # nettools
    oathToolkit  # for oathtool
    # ponymix
    pulsemixer
    python3
    rmlint
    sane-scripts
    sequoia
    snapper
    sops
    ssh-to-age
    sudo
    visidata
    w3m
    wireguard-tools
    youtube-dl
  ]
  ++ (if config.colinsane.gui.enable then
  [
    # GUI only
    aerc  # email client
    audacity
    chromium
    clinfo
    electrum

    # creds/session keys, etc
    { pkg = element-desktop; dir = ".config/Element"; }

    evince  # works on phosh
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
    gnome.gnome-terminal  # works on phosh
    gthumb
    inkscape
    libreoffice-fresh  # XXX colin: maybe don't want this on mobile
    logseq
    lollypop
    mesa-demos
    networkmanagerapplet

    # settings (electron app). TODO: can i manage these settings with home-manager?
    { pkg = obsidian; dir = ".config/obsidian"; }

    playerctl
    tdesktop  # broken on phosh
    vlc  # works on phosh
    whalebird # pleroma client. input is broken on phosh
    xterm  # broken on phosh
  ] else [])
  ++ (if config.colinsane.gui.enable && pkgs.system == "x86_64-linux" then
  [
    # x86_64 only

    # creds, but also 200 MB of node modules, etc
    { pkg = discord; dir = ".config/discord"; }

    kaiteki  # Pleroma client
    gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)

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

  pkglist = builtins.map (e: e.pkg or e) pkgspec;
  dirlist = builtins.concatLists (builtins.map (e: if e ? "dir" then [ e.dir ] else []) pkgspec);
in
{
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
  colinsane.home-manager.extraPackages = pkglist;
  # TODO: this should be gated behind home-manager being enabled...
  colinsane.impermanence.home-dirs = dirlist;
}
