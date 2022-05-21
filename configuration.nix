# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# USEFUL COMMANDS:
#   nix show-config
#   nix eval --raw <expr>  => print an expression. e.g. nixpkgs.raspberrypifw prints store path to the package
#   nix-option   ##  query options -- including their SET VALUE; similar to search: https://search.nixos.org/options
#   nixos-rebuild switch --upgrade   ## pull changes from the nixos channel (e.g. security updates) and rebuild

{ config, modulesPath, pkgs, specialArgs, options }:

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

  nixpkgs.overlays = [
    (self: super: {
      #### customized packages
      # nixos-unstable pleroma is too far out-of-date for our db
      pleroma = super.callPackage ./pkgs/pleroma { };
      # jackett doesn't allow customization of the bind address: this will probably always be here.
      jackett = self.callPackage ./pkgs/jackett { pkgs = super; };
      # fix abrupt HDD poweroffs as during reboot. patching systemd requires rebuilding nearly every package.
      # systemd = import ./pkgs/systemd { pkgs = super; };

      #### nixos-unstable packages
      # gitea: 1.16.5 contains a fix which makes manual user approval *actually* work.
      # https://github.com/go-gitea/gitea/pull/19119
      # safe to remove after 1.16.5 (or 1.16.7 if we need db compat?)
      gitea = pkgs.unstable.gitea;

      # try a newer rpi4 u-boot
      # ubootRaspberryPi4_64bit = pkgs.unstable.ubootRaspberryPi4_64bit;
      ubootRaspberryPi4_64bit = self.callPackage ./pkgs/ubootRaspberryPi4_64bit { pkgs = super; };
    })
  ];


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.11"; # Did you read the comment?

}

