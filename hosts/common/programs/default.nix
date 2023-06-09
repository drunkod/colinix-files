{ config, lib, pkgs, ... }:

{

  imports = [
    ./aerc.nix
    ./assorted.nix
    ./git.nix
    ./gnome-feeds.nix
    ./gpodder.nix
    ./imagemagick.nix
    ./jellyfin-media-player.nix
    ./kitty
    ./libreoffice.nix
    ./mpv.nix
    ./neovim.nix
    ./newsflash.nix
    ./offlineimap.nix
    ./ripgrep.nix
    ./splatmoji.nix
    ./sublime-music.nix
    ./vlc.nix
    ./web-browser.nix
    ./wireshark.nix
    ./zeal.nix
    ./zsh
  ];

  config = {
    # XXX: this might not be necessary. try removing this and cacert.unbundled (servo)?
    environment.etc."ssl/certs".source = "${pkgs.cacert.unbundled}/etc/ssl/certs/*";

    # steam requires system-level config for e.g. firewall or controller support
    # TODO: split into steam.nix
    programs.steam = lib.mkIf config.sane.programs.steam.enabled {
      enable = true;
      # not sure if needed: stole this whole snippet from the wiki
      remotePlay.openFirewall = true; # Open ports in the firewall for Steam Remote Play
      dedicatedServer.openFirewall = true; # Open ports in the firewall for Source Dedicated Server
    };
  };
}
