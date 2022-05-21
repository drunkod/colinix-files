# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# USEFUL COMMANDS:
#   nix show-config
#   nix eval --raw <expr>  => print an expression. e.g. nixpkgs.raspberrypifw prints store path to the package
#   nix-option   ##  query options -- including their SET VALUE; similar to search: https://search.nixos.org/options
#   nixos-rebuild switch --upgrade   ## pull changes from the nixos channel (e.g. security updates) and rebuild

{ config, pkgs, ... }:

{

  # enable flake support.
  # the real config root lives in flake.nix
  nix = {
    #package = pkgs.nixFlakes;
    package = pkgs.nixUnstable;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}

