{ config, pkgs }:


# useful devtools:
# bison
# dtc
# flex
# gcc
# gcc-arm-embedded
# gcc_multi
# rustup
# swig
with pkgs;
[
  backblaze-b2
  duplicity
  # TODO: this should be moved into `nix develop` in blog repo
  gnumake
  gnupg
  ifuse
  ipfs
  libimobiledevice
  lm_sensors  # for sensors-detect
  mix2nix
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
  wireguard-tools
  youtube-dl
  # TODO: this should be moved into `nix develop` in blog repo
  zola
]
++ (if config.colinsane.gui.enable then
with pkgs;
[
  # GUI only
  aerc  # email client
  audacity
  chromium
  clinfo
  electrum
  element-desktop  # broken on phosh
  evince  # works on phosh
  font-manager
  gimp  # broken on phosh
  gnome.dconf-editor
  gnome-feeds  # RSS reader (with claimed mobile support)
  gnome.file-roller
  gnome.gnome-maps  # works on phosh
  gnome.nautilus
  gnome-podcasts
  gnome.gnome-terminal  # works on phosh
  inkscape
  libreoffice-fresh  # XXX colin: maybe don't want this on mobile
  mesa-demos
  monero-gui
  networkmanagerapplet
  obsidian
  playerctl
  tdesktop  # broken on phosh
  vlc  # works on phosh
  whalebird # pleroma client. input is broken on phosh
  xterm  # broken on phosh
] else [])
++ (if config.colinsane.gui.enable && pkgs.system == "x86_64-linux" then
with pkgs;
[
  # x86_64 only
  discord
  kaiteki  # Pleroma client
  gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)
  signal-desktop
  spotify
  # hardenedMalloc solves a crash at startup
  (tor-browser-bundle-bin.override { useHardenedMalloc = false; })
  zecwallet-lite
] else [])

