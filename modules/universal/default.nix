{ pkgs, ... }:

{
  imports = [
    ./allocations.nix
    ./fs.nix
    ./home-manager
    ./home-packages.nix
    ./net.nix
    ./secrets.nix
    ./ssh.nix
    ./system-packages.nix
    ./users.nix
    ./vpn.nix
  ];

  time.timeZone = "America/Los_Angeles";

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
  environment.systemPackages = with pkgs; [
    # required for pam_mount
    gocryptfs
  ];

  security.pam.mount.enable = true;
  # security.pam.mount.debugLevel = 1;
  # security.pam.enableSSHAgentAuth = true; # ??
  # needed for `allow_other` in e.g. gocryptfs mounts
  # or i guess going through mount.fuse sets suid so that's not necessary?
  # programs.fuse.userAllowOther = true;
}

