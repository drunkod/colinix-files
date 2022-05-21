# docs:
#   https://nixos.wiki/wiki/Flakes
#   https://serokell.io/blog/practical-nix-flakes

{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    pkgs-gitea.url = "nixpkgs/c777cdf5c564015d5f63b09cc93bef4178b19b01";
    pkgs-mobile.url = "nixpkgs/7e567a3d092b7de69cdf5deaeb8d9526de230916";
    # this includes a patch to enable flake support
    mobile-nixos.url = "github:ngi-nix/mobile-nixos/afe022e1898aa05381077a89c3681784e6074458";
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    # XXX colin: is this right?
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, pkgs-gitea, pkgs-mobile, mobile-nixos, home-manager }: {
    nixosConfigurations.uninsane = nixpkgs.lib.nixosSystem {
      pkgs = import nixpkgs {
        system = "aarch64-linux";
        config.allowUnfree = true;
        overlays = [
          (self: super: {
            pkgs-gitea.system = "aarch64-linux";  # extraneous?
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
            gitea = pkgs-gitea.legacyPackages.aarch64-linux.gitea;

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

    nixosConfigurations.lappy = nixpkgs.lib.nixosSystem {
      pkgs = import nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
      system = "x86_64-linux";
      modules = [
        ({ pkgs, ... }: {
          nixpkgs.config.allowUnfree = true;
        })
        home-manager.nixosModules.home-manager {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.colin.imports = [ ./lappy/colin.nix ];
        }
        ./configuration.nix
        ./lappy/users.nix
        ./lappy/hardware.nix
      ];
    };
    nixosConfigurations.pda = pkgs-mobile.lib.nixosSystem {
      # inherit (self.packages.aarch64-linux) pkgs;
      system = "aarch64-linux";
      modules = [
        # ({ pkgs, ... }: {
        #   nixpkgs.config.allowUnfree = true;
        # })
        # home-manager.nixosModules.home-manager {
        #   home-manager.useGlobalPkgs = true;
        #   home-manager.useUserPackages = true;
        #   home-manager.users.colin.imports = [ ./colin.nix ];
        # }
        # ./configuration.nix
        # ./users.nix
        mobile-nixos.nixosModules.pine64-pinephone ({
          users.users.root.password = "147147";
        })
        # ({ pkgs, mobile-nixos, ... }: {
        #   imports = [
        #     (import "${mobile-nixos}/lib/configuration.nix" { device = "pine64-pinephone"; })
        #   ];
        # })
        # ({ pkgs, ... }: {
        #   imports = [
        #     <mobnixos>/devices/pine64-pinephone
        #   ];
        # })
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

