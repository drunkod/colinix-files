{ config, lib, pkgs, ... }:
let
  declPackageSet = pkgs: {
    package = null;
    suggestedPrograms = pkgs;
  };
in
{
  imports = [
    ./gnome.nix
    ./greetd.nix
    ./gtk.nix
    ./phosh.nix
    ./sway
    ./sxmo
    ./theme
  ];

  sane.programs.gameApps = declPackageSet [
    "animatch"
    "gnome-2048"
    "superTux"  # keyboard-only controls
    "superTuxKart"  # poor FPS on pinephone
  ];
  sane.programs.desktopGameApps = declPackageSet [
    # "andyetitmoves" # TODO: fix build!
    # "armagetronad"  # tron/lightcycles; WAN and LAN multiplayer
    # "cutemaze"      # meh: trivial maze game; qt6 and keyboard-only
    # "cuyo"          # trivial puyo-puyo clone
    "endless-sky"     # space merchantilism/exploration
    # "factorio"
    "frozen-bubble"   # WAN + LAN + 1P/2P bubble bobble
    # "hedgewars"     # WAN + LAN worms game (5~10 people online at any moment; <https://hedgewars.org>)
    # "libremines"    # meh: trivial minesweeper; qt6
    # "mario0"        # SMB + portal
    # "mindustry"
    # "minesweep-rs"  # CLI minesweeper
    # "nethack"
    # "osu-lazer"
    # "pinball"       # 3d pinball; kb/mouse. old sourceforge project
    # "powermanga"    # STYLISH space invaders derivative (keyboard-only)
    "shattered-pixel-dungeon"  # doesn't cross compile
    "space-cadet-pinball"  # LMB/RMB controls (bindable though. volume buttons?)
    "tumiki-fighters" # keyboard-only
    "vvvvvv"  # keyboard-only controls
  ];

  sane.programs.guiApps = declPackageSet (
    lib.optionals (pkgs.system == "x86_64-linux") [
      "x86GuiApps"
    ] ++ [
      # package sets
      "tuiApps"
      "gameApps"
    ] ++ [
      "alacritty"  # terminal emulator
      "calls"  # gnome calls (dialer/handler)
      # "celluloid"  # mpv frontend
      "chatty"  # matrix/xmpp/irc client
      "cozy"  # audiobook player
      "dialect"  # language translation
      "dino"  # XMPP client
      # "emote"
      "epiphany"  # gnome's web browser
      "evince"  # works on phosh
      "firefox"
      # "flare-signal"  # gtk4 signal client
      # "foliate"  # e-book reader
      "fractal"  # matrix client
      "g4music"  # local music player
      # "gnome.cheese"
      # "gnome-feeds"  # RSS reader (with claimed mobile support)
      # "gnome.file-roller"
      "gnome.geary"  # adaptive e-mail client
      "gnome.gnome-calculator"
      "gnome.gnome-calendar"
      "gnome.gnome-clocks"
      "gnome.gnome-maps"
      # "gnome-podcasts"
      # "gnome.gnome-system-monitor"
      # "gnome.gnome-terminal"  # works on phosh
      "gnome.gnome-weather"
      "gpodder"
      "gthumb"
      "gtkcord4"  # Discord client
      "komikku"
      "koreader"
      "lemoa"  # lemmy app
      # "lollypop"
      "mate.engrampa"  # archive manager
      "mepo"  # maps viewer
      "mpv"
      "networkmanagerapplet"  # for nm-connection-editor: it's better than not having any gui!
      "ntfy-sh"  # notification service
      # "newsflash"
      "pavucontrol"
      # "picard"  # music tagging
      # "libsForQt5.plasmatube"  # Youtube player
      "signal-desktop"
      "soundconverter"
      "spot"  # Gnome Spotfy client
      # "sublime-music"
      "tangram"  # web browser
      # "tdesktop"  # broken on phosh
      # "tokodon"
      "tuba"  # mastodon/pleroma client (stores pw in keyring)
      # "whalebird"  # pleroma client (Electron). input is broken on phosh.
      "wike"  # Wikipedia Reader
      "xdg-terminal-exec"
      "xterm"  # broken on phosh
    ]
  );

  sane.programs.desktopGuiApps = declPackageSet (
    [
      # package sets
      "desktopGameApps"
    ] ++ [
      "audacity"
      "blanket"  # ambient noise generator
      "brave"  # for the integrated wallet -- as a backup
      # "cantata"  # music player (mpd frontend)
      # "chromium"  # chromium takes hours to build. brave is chromium-based, distributed in binary form, so prefer it.
      "electrum"
      "element-desktop"
      "font-manager"
      # "gajim"  # XMPP client. cross build tries to import host gobject-introspection types (2023/09/01)
      "gimp"  # broken on phosh
      # "gnome.dconf-editor"
      # "gnome.file-roller"
      "gnome.gnome-disk-utility"
      "gnome.nautilus"  # file browser
      # "gnome.totem"  # video player, supposedly supports UPnP
      "handbrake"
      "hase"
      "inkscape"
      # "jellyfin-media-player"
      "kdenlive"
      "kid3"  # audio tagging
      "krita"
      "libreoffice"  # TODO: replace with an office suite that uses saner packaging?
      "mumble"
      # "nheko"  # Matrix chat client
      # "obsidian"
      # "rhythmbox"  # local music player
      "slic3r"
      "steam"
      "vlc"
      "wireshark"  # could maybe ship the cli as sysadmin pkg
    ]
  );

  sane.programs.handheldGuiApps = declPackageSet [
    "megapixels"  # camera app
    "portfolio-filemanager"
    "xarchiver"
  ];

  sane.programs.x86GuiApps = declPackageSet [
    "discord"
    # "gnome.zenity" # for kaiteki (it will use qarma, kdialog, or zenity)
    # "gpt2tc"  # XXX: unreliable mirror
    # "kaiteki"  # Pleroma client
    # "logseq"  # Personal Knowledge Management
    "losslesscut-bin"
    "makemkv"
    "monero-gui"
    # "signal-desktop"
    "spotify"
    "tor-browser-bundle-bin"
    "zecwallet-lite"
  ];


  sane.persist.sys.byStore.plaintext = lib.mkIf config.sane.programs.guiApps.enabled [
    "/var/lib/alsa"                # preserve output levels, default devices
    "/var/lib/colord"              # preserve color calibrations (?)
    "/var/lib/systemd/backlight"   # backlight brightness
  ];

  hardware.opengl = lib.mkIf config.sane.programs.guiApps.enabled ({
    enable = true;
    driSupport = lib.mkDefault true;
  } // (lib.optionalAttrs pkgs.stdenv.isx86_64 {
    # for 32 bit applications
    # upstream nixpkgs forbids setting driSupport32Bit unless specifically x86_64 (so aarch64 isn't allowed)
    driSupport32Bit = lib.mkDefault true;
  }));
}
