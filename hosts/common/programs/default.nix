{ pkgs, ... }:

{
  imports = [
    ./abaddon.nix
    ./aerc.nix
    ./alacritty.nix
    ./animatch.nix
    ./assorted.nix
    ./audacity.nix
    ./bemenu.nix
    ./brave.nix
    ./calls.nix
    ./cantata.nix
    ./catt.nix
    ./chatty.nix
    ./conky
    ./cozy.nix
    ./dialect.nix
    ./dino.nix
    ./element-desktop.nix
    ./epiphany.nix
    ./evince.nix
    ./feedbackd.nix
    ./firefox.nix
    ./flare-signal.nix
    ./fontconfig.nix
    ./fractal.nix
    ./fwupd.nix
    ./g4music.nix
    ./gajim.nix
    ./geary.nix
    ./git.nix
    ./gnome-feeds.nix
    ./gnome-keyring.nix
    ./gnome-weather.nix
    ./go2tv.nix
    ./gpodder.nix
    ./gthumb.nix
    ./gtkcord4.nix
    ./helix.nix
    ./imagemagick.nix
    ./jellyfin-media-player.nix
    ./komikku.nix
    ./koreader
    ./libreoffice.nix
    ./lemoa.nix
    ./loupe.nix
    ./mako.nix
    ./mepo.nix
    ./mimeo
    ./mopidy.nix
    ./mpv.nix
    ./msmtp.nix
    ./nautilus.nix
    ./neovim.nix
    ./newsflash.nix
    ./nheko.nix
    ./nix-index.nix
    ./notejot.nix
    ./ntfy-sh.nix
    ./obsidian.nix
    ./offlineimap.nix
    ./open-in-mpv.nix
    ./planify.nix
    ./playerctl.nix
    ./rhythmbox.nix
    ./ripgrep.nix
    ./sfeed.nix
    ./signal-desktop.nix
    ./splatmoji.nix
    ./spot.nix
    ./spotify.nix
    ./steam.nix
    ./stepmania.nix
    ./sublime-music.nix
    ./supertuxkart.nix
    ./sway-autoscaler
    ./swaynotificationcenter.nix
    ./tangram.nix
    ./tor-browser-bundle-bin.nix
    ./tuba.nix
    ./vlc.nix
    ./wike.nix
    ./wine.nix
    ./wireshark.nix
    ./wob.nix
    ./xarchiver.nix
    ./zeal.nix
    ./zecwallet-lite.nix
    ./zsh
  ];

  config = {
    # XXX: this might not be necessary. try removing this and cacert.unbundled (servo)?
    environment.etc."ssl/certs".source = "${pkgs.cacert.unbundled}/etc/ssl/certs/*";

  };
}
