{ ... }:

{
  imports = [
    ./users.nix
    ./home-manager.nix
    ./home-packages.nix
    ./system-packages.nix
  ];

  # programs.vim.defaultEditor = true;
  environment.variables = {
    EDITOR = "vim";
    # git claims it should use EDITOR, but it doesn't!
    GIT_EDITOR = "vim";
    # Electron apps should use native wayland backend:
    #   https://nixos.wiki/wiki/Slack#Wayland
    # Discord under sway crashes with this.
    # NIXOS_OZONE_WL = "1";
  };
}

