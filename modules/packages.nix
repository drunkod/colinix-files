{ config, lib, pkgs, ... }:

with lib;
with pkgs;
let
  cfg = config.sane.packages;

  imagemagick = pkgs.imagemagick.override {
    ghostscriptSupport = true;
  };

  consolePkgs = [
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
    { pkg = dino; private = [ ".local/share/dino" ]; }
    electrum

    # creds/session keys, etc
    { pkg = element-desktop; private = [ ".config/Element" ]; }
    # `emote` will show a first-run dialog based on what's in this directory.
    # mostly, it just keeps a LRU of previously-used emotes to optimize display order.
    # TODO: package [smile](https://github.com/mijorus/smile) for probably a better mobile experience.
    { pkg = emote; dir = [ ".local/share/Emote" ]; }
    evince  # works on phosh

    # { pkg = fluffychat-moby; dir = [ ".local/share/chat.fluffy.fluffychat" ]; }  # TODO: ship normal fluffychat on non-moby?

    foliate
    font-manager

    # XXX by default fractal stores its state in ~/.local/share/<UUID>.
    # after logging in, manually change ~/.local/share/keyrings/... to point it to some predictable subdir.
    # then reboot (so that libsecret daemon re-loads the keyring...?)
    # { pkg = fractal-latest; private = [ ".local/share/fractal" ]; }
    # { pkg = fractal-next; private = [ ".local/share/fractal" ]; }

    gajim  # XMPP client
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

    # XXX: we preserve the whole thing because if we only preserve gPodder/Downloads
    #   then startup is SLOW during feed import, and we might end up with zombie eps in the dl dir.
    { pkg = gpodder-configured; dir = [ "gPodder" ]; }

    gthumb
    handbrake
    inkscape

    kdenlive
    kid3  # audio tagging
    krita
    libreoffice-fresh  # XXX colin: maybe don't want this on mobile
    lollypop

    { pkg = mpv; dir = [ ".config/mpv/watch_later" ]; }

    networkmanagerapplet

    # not strictly necessary, but allows caching articles; offline use, etc.
    { pkg = newsflash; dir = [ ".local/share/news-flash" ]; }

    { pkg = nheko; private = [
      ".config/nheko"  # config file (including client token)
      ".cache/nheko"  # media cache
      ".local/share/nheko"  # per-account state database
    ]; }

    # settings (electron app). TODO: can i manage these settings with home-manager?
    { pkg = obsidian; dir = [ ".config/obsidian" ]; }

    pavucontrol
    # picard  # music tagging
    playerctl

    libsForQt5.plasmatube  # Youtube player

    soundconverter
    # sublime music persists any downloaded albums here.
    # it doesn't obey a conventional ~/Music/{Artist}/{Album}/{Track} notation, so no symlinking
    # config (e.g. server connection details) is persisted in ~/.config/sublime-music/config.json
    #   possible to pass config as a CLI arg (sublime-music -c config.json)
    # { pkg = sublime-music; dir = [ ".local/share/sublime-music" ]; }
    { pkg = sublime-music-mobile; dir = [ ".local/share/sublime-music" ]; }
    { pkg = tdesktop; private = [ ".local/share/TelegramDesktop" ]; }  # broken on phosh

    { pkg = tokodon; private = [ ".cache/KDE/tokodon" ]; }

    # vlc remembers play position in ~/.config/vlc/vlc-qt-interface.conf
    { pkg = vlc; dir = [ ".config/vlc" ]; }

    # pleroma client (Electron). input is broken on phosh.
    { pkg = whalebird; private = [ ".config/Whalebird" ]; }

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
    }); in { pkg = discord; private = [ ".config/discord" ]; })

    # kaiteki  # Pleroma client
    # gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)
    # gpt2tc  # XXX: unreliable mirror

    logseq
    losslesscut-bin
    makemkv

    # actual monero blockchain (not wallet/etc; safe to delete, just slow to regenerate)
    { pkg = monero-gui; dir = [ ".bitmonero" ]; }

    # creds, media
    { pkg = signal-desktop; private = [ ".config/Signal" ]; }

    # creds. TODO: can i manage this with home-manager?
    { pkg = spotify; dir = [ ".config/spotify" ]; }

    # hardenedMalloc solves a crash at startup
    (tor-browser-bundle-bin.override { useHardenedMalloc = false; })

    # zcash coins. safe to delete, just slow to regenerate (10-60 minutes)
    { pkg = zecwallet-lite; private = [ ".zcash" ]; }
  ] else []);

  # general-purpose utilities that we want any user to be able to access
  #   (specifically: root, in case of rescue)
  systemPkgs = [
    btrfs-progs
    cacert.unbundled  # some services require unbundled /etc/ssl/certs
    cryptsetup
    dig
    efibootmgr
    fatresize
    fd
    file
    gawk
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
  ];

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

  pkgSpec = types.submodule {
    options = {
      pkg = mkOption {
        type = types.package;
      };
      dir = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "list of home-relative paths to persist for this package";
      };
      private = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "list of home-relative paths to persist (in encrypted format) for this package";
      };
    };
  };

  toPkgSpec = types.coercedTo types.package (p: { pkg = p; }) pkgSpec;
in
{
  options = {
    # packages to deploy to the user's home
    sane.packages.extraUserPkgs = mkOption {
      default = [ ];
      type = types.listOf toPkgSpec;
    };
    sane.packages.extraGuiPkgs = mkOption {
      default = [ ];
      type = types.listOf toPkgSpec;
      description = "packages to only ship if gui's enabled";
    };
    sane.packages.enableConsolePkgs = mkOption {
      default = false;
      type = types.bool;
    };
    sane.packages.enableGuiPkgs = mkOption {
      default = false;
      type = types.bool;
    };
    sane.packages.enableDevPkgs = mkOption {
      description = ''
        enable packages that are useful for building other software by hand.
        you should prefer to keep this disabled except when prototyping, e.g. packaging new software.
      '';
      default = false;
      type = types.bool;
    };
    sane.packages.enableSystemPkgs = mkOption {
      default = false;
      type = types.bool;
      description = "enable system-wide packages";
    };

    sane.packages.enabledUserPkgs = mkOption {
      default = cfg.extraUserPkgs
        ++ (if cfg.enableConsolePkgs then consolePkgs else [])
        ++ (if cfg.enableGuiPkgs then guiPkgs ++ cfg.extraGuiPkgs else [])
        ++ (if cfg.enableDevPkgs then devPkgs else [])
      ;
      type = types.listOf toPkgSpec;
      description = "generated from other config options";
    };
  };

  config = {
    environment.systemPackages = mkIf cfg.enableSystemPkgs systemPkgs;
    sane.persist.home.plaintext = concatLists (map (p: p.dir) cfg.enabledUserPkgs);
    sane.persist.home.private = concatLists (map (p: p.private) cfg.enabledUserPkgs);
    # XXX: this might not be necessary. try removing this and cacert.unbundled?
    environment.etc."ssl/certs".source = mkIf cfg.enableSystemPkgs "${pkgs.cacert.unbundled}/etc/ssl/certs/*";
  };
}
