# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, modulesPath, pkgs, specialArgs, options }:

let
  pkgsUnstable = import (builtins.fetchTarball {
    # Descriptive name to make the store path easier to identify
    name = "nixos-unstable-2022-05-05";
    # Commit hash for master on above date (s/commits/archive and append .tar.gz)
    # see https://github.com/NixOS/nixpkgs/commits/nixos-unstable
    url = "https://github.com/NixOS/nixpkgs/archive/c777cdf5c564015d5f63b09cc93bef4178b19b01.tar.gz";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0r2xhflcy5agaz4a3b8pxiyiwh32s1kl3swv73flnj1x3v69s8bm";
  }) {};
in
{
  imports = [
    ./cfg
    ./modules
  ];

  nixpkgs.overlays = [
    (self: super: {
      #### customized packages
      # nixos-unstable pleroma is too far out-of-date for our db
      pleroma = super.callPackage ./pkgs/pleroma { };
      # jackett doesn't allow customization of the bind address: this will probably always be here.
      jackett = self.callPackage ./pkgs/jackett { pkgs = super; };

      #### nixos-unstable packages
      # gitea: 1.16.5 contains a fix which makes manual user approval *actually* work.
      # https://github.com/go-gitea/gitea/pull/19119
      # safe to remove after 1.16.5 (or 1.16.7 if we need db compat?)
      gitea = pkgsUnstable.gitea;

      # try a newer rpi4 u-boot
      # ubootRaspberryPi4_64bit = pkgsUnstable.ubootRaspberryPi4_64bit;
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

