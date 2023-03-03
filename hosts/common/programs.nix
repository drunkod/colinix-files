{ lib, pkgs, ... }:

let
  inherit (builtins) attrNames concatLists;
  inherit (lib) mapAttrs mapAttrsToList mkDefault mkMerge optional;

  flattenedPkgs = pkgs // (with pkgs; {
    # XXX can't `inherit` a nested attr, so we move them to the toplevel
    "cacert.unbundled" = pkgs.cacert.unbundled;
    "gnome.cheese" = gnome.cheese;
    "gnome.dconf-editor" = gnome.dconf-editor;
    "gnome.file-roller" = gnome.file-roller;
    "gnome.gnome-disk-utility" = gnome.gnome-disk-utility;
    "gnome.gnome-maps" = gnome.gnome-maps;
    "gnome.nautilus" = gnome.nautilus;
    "gnome.gnome-system-monitor" = gnome.gnome-system-monitor;
    "gnome.gnome-terminal" = gnome.gnome-terminal;
    "gnome.gnome-weather" = gnome.gnome-weather;
    "libsForQt5.plasmatube" = libsForQt5.plasmatube;
  });

  sysadminPkgs = {
    inherit (flattenedPkgs)
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
      subversion
      tcpdump
      tree
      usbutils
      wget
    ;
  };
  sysadminExtraPkgs = {
    # application-specific packages
    inherit (pkgs)
      backblaze-b2
      duplicity
      sqlite  # to debug sqlite3 databases
    ;
  };

  iphonePkgs = {
    inherit (pkgs)
      ifuse
      ipfs
      libimobiledevice
    ;
  };

  tuiPkgs = {
    inherit (pkgs)
      aerc  # email client
      offlineimap  # email mailox sync
      visidata  # TUI spreadsheet viewer/editor
      w3m
    ;
  };

  # TODO: split these into smaller groups.
  # - transcoders (ffmpeg, imagemagick) only wanted on desko/lappy ("powerutils"?)
  consolePkgs = {
    inherit (pkgs)
      cdrtools
      dmidecode
      efivar
      flashrom
      fwupd
      ghostscript  # TODO: imagemagick wrapper should add gs to PATH
      gnupg
      gocryptfs
      gopass
      gopass-jsonapi
      imagemagick
      kitty  # TODO: move to GUI, but `ssh servo` from kitty sets `TERM=xterm-kitty` in the remove and breaks things
      libsecret  # for managing user keyrings
      lm_sensors  # for sensors-detect
      lshw
      ffmpeg
      memtester
      # networkmanager
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
      ssh-to-age
      sudo
      # tageditor  # music tagging
      unar
      wireguard-tools
      xdg-utils  # for xdg-open
      # youtube-dl
      yt-dlp
    ;
  };

  guiPkgs = {
    inherit (flattenedPkgs)
      celluloid  # mpv frontend
      clinfo
      emote
      evince  # works on phosh

      # { pkg = fluffychat-moby; dir = [ ".local/share/chat.fluffy.fluffychat" ]; }  # TODO: ship normal fluffychat on non-moby?

      # foliate  # e-book reader

      # XXX by default fractal stores its state in ~/.local/share/<UUID>.
      # after logging in, manually change ~/.local/share/keyrings/... to point it to some predictable subdir.
      # then reboot (so that libsecret daemon re-loads the keyring...?)
      # { pkg = fractal-latest; private = [ ".local/share/fractal" ]; }
      # { pkg = fractal-next; private = [ ".local/share/fractal" ]; }

      # "gnome.cheese"
      "gnome.dconf-editor"
      gnome-feeds  # RSS reader (with claimed mobile support)
      "gnome.file-roller"
      # "gnome.gnome-maps"  # works on phosh
      "gnome.nautilus"
      # gnome-podcasts
      "gnome.gnome-system-monitor"
      "gnome.gnome-terminal"  # works on phosh
      "gnome.gnome-weather"
      gpodder-configured
      gthumb
      # lollypop
      mpv
      networkmanagerapplet
      # newsflash
      nheko
      pavucontrol
      # picard  # music tagging
      playerctl
      # "libsForQt5.plasmatube"  # Youtube player
      soundconverter
      # sublime music persists any downloaded albums here.
      # it doesn't obey a conventional ~/Music/{Artist}/{Album}/{Track} notation, so no symlinking
      # config (e.g. server connection details) is persisted in ~/.config/sublime-music/config.json
      #   possible to pass config as a CLI arg (sublime-music -c config.json)
      # { pkg = sublime-music; dir = [ ".local/share/sublime-music" ]; }
      sublime-music-mobile
      # tdesktop  # broken on phosh
      # tokodon
      vlc
      # pleroma client (Electron). input is broken on phosh. TODO(2023/02/02): fix electron19 input (insecure)
      # whalebird
      xterm  # broken on phosh
    ;
  };
  desktopGuiPkgs = {
    inherit (flattenedPkgs)
      audacity
      chromium
      dino
      electrum
      element-desktop
      font-manager
      gajim  # XMPP client
      gimp  # broken on phosh
      "gnome.gnome-disk-utility"
      inkscape
      kdenlive
      kid3  # audio tagging
      krita
      libreoffice-fresh  # XXX colin: maybe don't want this on mobile
      obsidian
    ;
  };
  x86GuiPkgs = {
    inherit (pkgs)
      discord

      # kaiteki  # Pleroma client
      # gnome.zenity # for kaiteki (it will use qarma, kdialog, or zenity)
      # gpt2tc  # XXX: unreliable mirror

      # TODO(unpin): handbrake is broken on aarch64-linux 2023/01/29
      handbrake

      logseq
      losslesscut-bin
      makemkv
      monero-gui
      signal-desktop
      spotify
      tor-browser-bundle-bin
      zecwallet-lite
    ;
  };

  # define -- but don't enable -- the packages in some attrset.
  # use `mkDefault` for the package here so we can customize some of them further down this file
  declarePkgs = pkgsAsAttrs: mapAttrs (_n: p: {
    package = mkDefault p;
  }) pkgsAsAttrs;
in
{
  config = {
    sane.programs = mkMerge [
      (declarePkgs consolePkgs)
      (declarePkgs desktopGuiPkgs)
      (declarePkgs guiPkgs)
      (declarePkgs iphonePkgs)
      (declarePkgs sysadminPkgs)
      (declarePkgs sysadminExtraPkgs)
      (declarePkgs tuiPkgs)
      (declarePkgs x86GuiPkgs)
      {
        # link the various package sets into their own meta packages
        consoleUtils = {
          package = null;
          suggestedPrograms = attrNames consolePkgs;
        };
        desktopGuiApps = {
          package = null;
          suggestedPrograms = attrNames desktopGuiPkgs;
        };
        guiApps = {
          package = null;
          suggestedPrograms = (attrNames guiPkgs)
            ++ [ "tuiApps" ]
            ++ optional (pkgs.system == "x86_64-linux") "x86GuiApps";
        };
        iphoneUtils = {
          package = null;
          suggestedPrograms = attrNames iphonePkgs;
        };
        sysadminUtils = {
          package = null;
          suggestedPrograms = attrNames sysadminPkgs;
        };
        sysadminExtraUtils = {
          package = null;
          suggestedPrograms = attrNames sysadminExtraPkgs;
        };
        tuiApps = {
          package = null;
          suggestedPrograms = attrNames tuiPkgs;
        };
        x86GuiApps = {
          package = null;
          suggestedPrograms = attrNames x86GuiPkgs;
        };
      }
      {
        # nontrivial package definitions
        imagemagick.package = pkgs.imagemagick.override {
          ghostscriptSupport = true;
        };

        dino.private = [ ".local/share/dino" ];

        # creds, but also 200 MB of node modules, etc
        discord = {
          package = pkgs.discord.override {
            # XXX 2022-07-31: fix to allow links to open in default web-browser:
            #   https://github.com/NixOS/nixpkgs/issues/78961
            nss = pkgs.nss_latest;
          };
          private = [ ".config/discord" ];
        };

        # creds/session keys, etc
        element-desktop.private = [ ".config/Element" ];

        # `emote` will show a first-run dialog based on what's in this directory.
        # mostly, it just keeps a LRU of previously-used emotes to optimize display order.
        # TODO: package [smile](https://github.com/mijorus/smile) for probably a better mobile experience.
        emote.dir = [ ".local/share/Emote" ];

        # XXX: we preserve the whole thing because if we only preserve gPodder/Downloads
        #   then startup is SLOW during feed import, and we might end up with zombie eps in the dl dir.
        gpodder-configured.dir = [ "gPodder" ];

        # actual monero blockchain (not wallet/etc; safe to delete, just slow to regenerate)
        # XXX: is it really safe to persist this? it doesn't have info that could de-anonymize if captured?
        monero-gui.dir = [ ".bitmonero" ];

        mpv.dir = [ ".config/mpv/watch_later" ];

        # not strictly necessary, but allows caching articles; offline use, etc.
        newsflash.dir = [ ".local/share/news-flash" ];
        nheko.private = [
          ".config/nheko"  # config file (including client token)
          ".cache/nheko"  # media cache
          ".local/share/nheko"  # per-account state database
        ];

        # settings (electron app)
        obsidian.dir = [ ".config/obsidian" ];

        # creds, media
        signal-desktop.private = [ ".config/Signal" ];


        # creds, widevine .so download. TODO: could easily manage these statically.
        spotify.dir = [ ".config/spotify" ];

        # sublime music persists any downloaded albums here.
        # it doesn't obey a conventional ~/Music/{Artist}/{Album}/{Track} notation, so no symlinking
        # config (e.g. server connection details) is persisted in ~/.config/sublime-music/config.json
        #   possible to pass config as a CLI arg (sublime-music -c config.json)
        # { pkg = sublime-music; dir = [ ".local/share/sublime-music" ]; }
        sublime-music-mobile.dir = [ ".local/share/sublime-music" ];

        tdesktop.private = [ ".local/share/TelegramDesktop" ];

        tokodon.private = [ ".cache/KDE/tokodon" ];

        # hardenedMalloc solves a crash at startup
        # TODO 2023/02/02: is this safe to remove yet?
        tor-browser-bundle-bin.package = pkgs.tor-browser-bundle-bin.override {
          useHardenedMalloc = false;
        };

        # vlc remembers play position in ~/.config/vlc/vlc-qt-interface.conf
        vlc.dir = [ ".config/vlc" ];

        whalebird.private = [ ".config/Whalebird" ];

        # zcash coins. safe to delete, just slow to regenerate (10-60 minutes)
        zecwallet-lite.private = [ ".zcash" ];
      }
    ];

    # XXX: this might not be necessary. try removing this and cacert.unbundled (servo)?
    environment.etc."ssl/certs".source = "${pkgs.cacert.unbundled}/etc/ssl/certs/*";
  };
}
