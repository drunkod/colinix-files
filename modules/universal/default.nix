{ pkgs, ... }:

{
  imports = [
    ./allocations.nix
    ./env
    ./fs.nix
    ./secrets.nix
    ./users.nix
    ./vpn.nix
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

  # allow `nix flake ...` command
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}

