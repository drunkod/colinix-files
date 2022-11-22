{ config, lib, pkgs, ... }:

with lib;
with pkgs;
let
  cfg = config.sane.home-packages;
  universalPkgs = [
    backblaze-b2
    cdrtools
    duplicity
    gnupg
    gocryptfs
    gopass
    gopass-jsonapi
    ifuse
    ipfs
    libimobiledevice
    libsecret  # for managing user keyrings
    lm_sensors  # for sensors-detect
    lshw
    ffmpeg
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
  ];

  guiPkgs = [
    # GUI only
    aerc  # email client
    audacity
    celluloid  # mpv frontend
    chromium
    clinfo
    { pkg = dino; private = ".local/share/dino"; }
    electrum

    # creds/session keys, etc
    { pkg = element-desktop; private = ".config/Element"; }
    # `emote` will show a first-run dialog based on what's in this directory.
    # mostly, it just keeps a LRU of previously-used emotes to optimize display order.
    # TODO: package [smile](https://github.com/mijorus/smile) for probably a better mobile experience.
    { pkg = emote; dir = ".local/share/Emote"; }
    evince  # works on phosh

    # { pkg = fluffychat-moby; dir = ".local/share/chat.fluffy.fluffychat"; }  # TODO: ship normal fluffychat on non-moby?

    foliate
    font-manager

    # XXX by default fractal stores its state in ~/.local/share/<UUID>.
    # after logging in, manually change ~/.local/share/keyrings/... to point it to some predictable subdir.
    # then reboot (so that libsecret daemon re-loads the keyring...?)
    { pkg = fractal-next; private = ".local/share/fractal"; }

    gimp  # broken on phosh
    gnome.cheese
    gnome.dconf-editor
    gnome-feeds  # RSS reader (with claimed mobile support)
    gnome.file-roller
    gnome.gnome-disk-utility
    gnome.gnome-maps  # works on phosh
    gnome.nautilus
    # gnome-podcasts
    gnome.gnome-system-monitor
    gnome.gnome-terminal  # works on phosh
    gnome.gnome-weather

    { pkg = gpodder-configured; dir = "gPodder/Downloads"; }

    gthumb
    handbrake
    inkscape

    kdenlive
    kid3  # audio tagging
    krita
    libreoffice-fresh  # XXX colin: maybe don't want this on mobile
    lollypop
    mesa-demos

    { pkg = mpv; dir = ".config/mpv/watch_later"; }

    networkmanagerapplet

    # not strictly necessary, but allows caching articles; offline use, etc.
    { pkg = newsflash; dir = ".local/share/news-flash"; }

    # settings (electron app). TODO: can i manage these settings with home-manager?
    { pkg = obsidian; dir = ".config/obsidian"; }

    pavucontrol
    # picard  # music tagging
    playerctl

    libsForQt5.plasmatube  # Youtube player

    soundconverter
    # sublime music persists any downloaded albums here.
    # it doesn't obey a conventional ~/Music/{Artist}/{Album}/{Track} notation, so no symlinking
    # config (e.g. server connection details) is persisted in ~/.config/sublime-music/config.json
    #   possible to pass config as a CLI arg (sublime-music -c config.json)
    { pkg = sublime-music; dir = ".local/share/sublime-music"; }
    tdesktop  # broken on phosh

    { pkg = tokodon; dir = ".cache/KDE/tokodon"; }

    # vlc remembers play position in ~/.config/vlc/vlc-qt-interface.conf
    { pkg = vlc; dir = ".config/vlc"; }

    whalebird # pleroma client. input is broken on phosh
    xdg-utils  # for xdg-open
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
  devPkgs = [
    bison
    dtc
    flex
    gcc
    gdb
    # gcc-arm-embedded
    # gcc_multi
    gnumake
    mercurial
    mix2nix
    rustup
    swig
  ];
in
{
  options = {
    sane.home-packages.enableGuiPkgs = mkOption {
      default = false;
      type = types.bool;
    };
    sane.home-packages.enableDevPkgs = mkOption {
      description = ''
        enable packages that are useful for building other software by hand.
        you should prefer to keep this disabled except when prototyping, e.g. packaging new software.
      '';
      default = false;
      type = types.bool;
    };
  };
  config = {
    sane.home-manager.extraPackages = universalPkgs
      ++ (if cfg.enableGuiPkgs then guiPkgs else [])
      ++ (if cfg.enableDevPkgs then devPkgs else []);
  };
}
