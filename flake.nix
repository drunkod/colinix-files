# docs:
#   https://nixos.wiki/wiki/Flakes
#   https://serokell.io/blog/practical-nix-flakes

{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    pkgsUnstable.url = "nixpkgs/c777cdf5c564015d5f63b09cc93bef4178b19b01";
  };
  outputs = { self, pkgsUnstable, nixpkgs }: {
    nixosConfigurations.uninsane = nixpkgs.lib.nixosSystem {
      # inherit (self.packages.aarch64-linux) pkgs;
      pkgs = import nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;
        overlays = [
          (self: super: {
            pkgsUnstable.system = "aarch64-linux";  # extraneous?
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
            gitea = pkgsUnstable.legacyPackages.aarch64-linux.gitea;

            # try a newer rpi4 u-boot
            # ubootRaspberryPi4_64bit = pkgs.unstable.ubootRaspberryPi4_64bit;
            ubootRaspberryPi4_64bit = self.callPackage ./pkgs/ubootRaspberryPi4_64bit { pkgs = super; };
          })
        ];
      };
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        ./cfg
        ./modules
        ({ pkgs, ... }: {
          # This value determines the NixOS release from which the default
          # settings for stateful data, like file locations and database versions
          # on your system were taken. It‘s perfectly fine and recommended to leave
          # this value at the release version of the first install of this system.
          # Before changing this value read the documentation for this option
          # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
          system.stateVersion = "21.11"; # Did you read the comment?
        })
      ];
    };
    # packages = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system:
    #   {
    #     pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
    #   }
    # );
    # flake-utils.lib.eachDefaultSystem (system:
    #   let pkgs = nixpkgs.legacyPackages.${system};
    #   in {
    #     # packages.hello = pkgs.hello;

    #     # devShell = pkgs.mkShell { buildInputs = [ pkgs.hello pkgs.cowsay ]; };
    #     nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
    #       system = "${system}";
    #     };
    #   }
    # );
  };
}

