{ config, lib, pkgs, ... }:
{
  imports = [
    ./gnome.nix
    ./greetd.nix
    ./gtk.nix
    ./phosh.nix
    ./sway
    ./sxmo
  ];

  sane.programs.guiApps = {
    package = null;
    suggestedPrograms = lib.optionals (pkgs.system == "x86_64-linux") [
      "x86GuiApps"
    ] ++ [
      # package sets
      "tuiApps"
    ] ++ [
      "alacritty"  # terminal emulator
      # "celluloid"  # mpv frontend
      "chatty"  # matrix/xmpp/irc client
      "cozy"  # audiobook player
      "dino"  # XMPP client
      # "emote"
      "epiphany"  # gnome's web browser
      "evince"  # works on phosh
      "firefox"
      # "foliate"  # e-book reader
      # "fractal"  # matrix client
      "g4music"  # local music player
      # "gnome.cheese"
      # "gnome-feeds"  # RSS reader (with claimed mobile support)
      # "gnome.file-roller"
      # "gnome.gnome-maps"  # works on phosh
      # "gnome-podcasts"
      # "gnome.gnome-system-monitor"
      # "gnome.gnome-terminal"  # works on phosh
      "gnome.gnome-weather"
      "gpodder"
      "gthumb"
      "komikku"
      "koreader"
      "lemoa"  # lemmy app
      # "lollypop"
      "mate.engrampa"  # archive manager
      "mepo"  # maps viewer
      "mpv"
      # "networkmanagerapplet"
      # "newsflash"
      "pavucontrol"
      # "picard"  # music tagging
      # "libsForQt5.plasmatube"  # Youtube player
      "soundconverter"
      # "sublime-music"
      "tangram"  # web browser
      # "tdesktop"  # broken on phosh
      # "tokodon"
      "tuba"  # mastodon/pleroma client (stores pw in keyring)
      # "whalebird"  # pleroma client (Electron). input is broken on phosh.
      "xterm"  # broken on phosh
    ];
  };

  sane.programs.desktopGuiApps = {
    package = null;
    suggestedPrograms = [
      "audacity"
      "blanket"  # ambient noise generator
      "brave"  # for the integrated wallet -- as a backup
      "cantata"  # music player (mpd frontend)
      # "chromium"  # chromium takes hours to build. brave is chromium-based, distributed in binary form, so prefer it.
      "electrum"
      "element-desktop"
      # "font-manager"  #< depends on webkitgtk4_0 (expensive to build)
      "gajim"  # XMPP client. cross build tries to import host gobject-introspection types (2023/09/01)
      "gimp"  # broken on phosh
      "gnome.dconf-editor"
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
      "nheko"
      "obsidian"
      "rhythmbox"  # local music player
      "slic3r"
      "steam"
      "vlc"
      "wireshark"  # could maybe ship the cli as sysadmin pkg
    ];
  };

  sane.programs.handheldGuiApps = {
    package = null;
    suggestedPrograms = [
      "megapixels"  # camera app
      "portfolio-filemanager"
      "xarchiver"
    ];
  };

  sane.programs.x86GuiApps = {
    package = null;
    suggestedPrograms = [
      "discord"
      # "gnome.zenity" # for kaiteki (it will use qarma, kdialog, or zenity)
      # "gpt2tc"  # XXX: unreliable mirror
      # "kaiteki"  # Pleroma client
      # "logseq"  # Personal Knowledge Management
      "losslesscut-bin"
      "makemkv"
      "monero-gui"
      "signal-desktop"
      "spotify"
      "tor-browser-bundle-bin"
      "zecwallet-lite"
    ];
  };

  sane.persist.sys.plaintext = lib.mkIf config.sane.programs.guiApps.enabled [
    "/var/lib/alsa"                # preserve output levels, default devices
    "/var/lib/colord"              # preserve color calibrations (?)
    "/var/lib/systemd/backlight"   # backlight brightness
  ];
}
