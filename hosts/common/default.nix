{ pkgs, ... }:
{
  imports = [
    ./bluetooth.nix
    ./feeds.nix
    ./fs.nix
    ./hardware
    ./i2p.nix
    ./machine-id.nix
    ./net.nix
    ./secrets.nix
    ./ssh.nix
    ./users.nix
    ./vpn.nix
  ];

  sane.home-manager.enable = true;
  sane.nixcache.enable-trusted-keys = true;
  sane.packages.enableConsolePkgs = true;
  sane.packages.enableSystemPkgs = true;

  sane.persist.sys.plaintext = [
    "/var/log"
    "/var/backup"  # for e.g. postgres dumps
    # TODO: move elsewhere
    "/var/lib/alsa"                # preserve output levels, default devices
    "/var/lib/colord"              # preserve color calibrations (?)
    "/var/lib/machines"            # maybe not needed, but would be painful to add a VM and forget.
  ];

  nixpkgs.config.allowUnfree = true;

  # time.timeZone = "America/Los_Angeles";
  time.timeZone = "Etc/UTC";  # DST is too confusing for me => use a stable timezone

  # allow `nix flake ...` command
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # TODO: move this into home-manager?
  fonts = {
    enableDefaultFonts = true;
    fonts = with pkgs; [ font-awesome twitter-color-emoji hack-font ];
    fontconfig.enable = true;
    fontconfig.defaultFonts = {
      emoji = [ "Font Awesome 6 Free" "Twitter Color Emoji" ];
      monospace = [ "Hack" ];
      serif = [ "DejaVu Serif" ];
      sansSerif = [ "DejaVu Sans" ];
    };
  };

  # disable non-required packages like nano, perl, rsync, strace
  environment.defaultPackages = [];

  # programs.vim.defaultEditor = true;
  environment.variables = {
    EDITOR = "vim";
    # git claims it should use EDITOR, but it doesn't!
    GIT_EDITOR = "vim";
    # TODO: these should be moved to `home.sessionVariables` (home-manager)
    # Electron apps should use native wayland backend:
    #   https://nixos.wiki/wiki/Slack#Wayland
    # Discord under sway crashes with this.
    # NIXOS_OZONE_WL = "1";
    # LIBGL_ALWAYS_SOFTWARE = "1";
  };
  # enable zsh completions
  environment.pathsToLink = [ "/share/zsh" ];

  # link debug symbols into /run/current-system/sw/lib/debug
  # hopefully picked up by gdb automatically?
  environment.enableDebugInfo = true;
}
