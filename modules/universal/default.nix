{ pkgs, ... }:

{
  imports = [
    ./fs.nix
    ./home-manager.nix
    ./nix-cache.nix
    ./secrets.nix
    ./users.nix
  ];

  time.timeZone = "America/Los_Angeles";

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
  };
}

