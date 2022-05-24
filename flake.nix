# docs:
#   https://nixos.wiki/wiki/Flakes
#   https://serokell.io/blog/practical-nix-flakes

# TODO:
#   cross compiling:
#     https://nixos.wiki/wiki/Cross_Compiling
#     https://nixos.wiki/wiki/NixOS_on_ARM
#     overlays = [{ ... }: {
#       nixpkgs.crossSystem.system = "aarch64-linux";
#     }];

{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.11";
    pkgs-gitea.url = "nixpkgs/c777cdf5c564015d5f63b09cc93bef4178b19b01";
    # pkgs-mobile.url = "nixpkgs/6daa4a5c045d40e6eae60a3b6e427e8700f1c07f"; # currently pinned to mobile-nixos tip  -> fails building lvgui
    pkgs-mobile.url = "nixpkgs/7e567a3d092b7de69cdf5deaeb8d9526de230916";  # 2021/06/21, coordinated with mobile-nixos 85557dca93ae574eaa7dc7b1877edf681a280d35 ; builds linux, but no errors after running for 4 hours
    # pkgs-mobile.url = "nixpkgs/cbe587c735b734405f56803e267820ee1559e6c1";  # successful mobile-nixos build https://hydra.nixos.org/eval/1759474#tabs-inputs
    # pkgs-mobile.url = "nixpkgs/48037fd90426e44e4bf03e6479e88a11453b9b66";  # successful mobile-nixos build 2022/05/19 https://hydra.nixos.org/eval/1762659#tabs-inputs
    # pkgs-mobile.url = "nixpkgs/1d7db1b9e4cf1ee075a9f52e5c36f7b9f4207502"; 
    # pkgs-mobile.url = "nixpkgs/43ff6cb1c027d13dc938b88eb099462210fea52f";
    # pkgs-mobile.url = "nixpkgs/98bb5b77c8c6666824a4c13d23befa1e07210ef1";  # mobile-nixos build 2022/02/10 https://hydra.nixos.org/eval/1743260#tabs-inputs fails building lvgui
    # pkgs-mobile.url = "nixpkgs/nixos-21.11";  # linux fails at config time
    # pkgs-mobile.url = "nixpkgs/5aaed40d22f0d9376330b6fa413223435ad6fee5";  # (untested) associated with HN comment 2022/01/16 https://hydra.nixos.org/build/164693256#tabs-buildinputs -- still tries to compile linux from source
    # pkgs-mobile.url = "nixpkgs/23d785aa6f853e6cf3430119811c334025bbef55";  # latest mobile-nixos:unstable:device.pine64-pinephone.aarch64-linux build 2022/02/20 https://hydra.nixos.org/build/167888996#tabs-buildinputs  -- still tries to compile linux from source, fails building lvgui
    # this includes a patch to enable flake support
    mobile-nixos = {
      url = "github:ngi-nix/mobile-nixos/afe022e1898aa05381077a89c3681784e6074458";
      inputs.nixpkgs.follows = "pkgs-mobile";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nurpkgs.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, pkgs-gitea, pkgs-mobile, mobile-nixos, home-manager, nurpkgs }: {
    machines.uninsane = self.decl-bootable-machine { name = "uninsane"; system = "aarch64-linux"; };
    machines.desko = self.decl-bootable-machine { name = "desko"; system = "x86_64-linux"; };
    machines.lappy = self.decl-bootable-machine { name = "lappy"; system = "x86_64-linux"; };

    machines.moby = {
      nixosConfiguration = pkgs-mobile.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit home-manager; inherit nurpkgs; };
        modules = [
          mobile-nixos.nixosModules.pine64-pinephone ({
            users.users.root.password = "147147";
          })
          ({ config, pkgs, ... }: {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ nurpkgs.overlay ];
          })
          ./machines/moby
        ];
      };
      img = (pkgs-mobile.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit home-manager; inherit nurpkgs; };
        modules = [
          mobile-nixos.nixosModules.pine64-pinephone ({
            users.users.root.password = "147147";
          })
          ({ config, pkgs, ... }: {
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [ nurpkgs.overlay ];
          })
          ./machines/moby
        ];
      }).config.mobile.outputs.u-boot.disk-image;
    };

    nixosConfigurations = builtins.mapAttrs (name: value: value.nixosConfiguration) self.machines;
    imgs = builtins.mapAttrs (name: value: value.img) self.machines;

    decl-machine = { name, system, extraModules ? [] }: (nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = self.genpkgs."${system}".pkgs;
        specialArgs = { inherit home-manager; inherit nurpkgs; };
        modules = [
          ./configuration.nix
          ./modules
          ./machines/${name}
        ] ++ extraModules;
    });

    # this produces a EFI-bootable .img file (GPT with / and /boot).
    # after building this, steps are:
    #   run `btrfs-convert --uuid copy <device>`
    #   boot, checkout this flake into /etc/nixos AND UPDATE THE UUIDS IT REFERENCES.
    #   then `nixos-rebuild ...`
    decl-img = { name, system, extraModules ? [] }: (
      (self.decl-machine { inherit name; inherit system; extraModules = extraModules ++ [./image.nix]; })
        .config.system.build.raw
    );

    decl-bootable-machine = { name, system }: {
      nixosConfiguration = self.decl-machine { inherit name; inherit system; };
      img = self.decl-img { inherit name; inherit system; };
    };

    # apply all our package overlays, but to all platforms possible.
    # genpkgs = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system:
    genpkgs = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system:
      {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;

          overlays = [
            #mobile-nixos.overlay
            nurpkgs.overlay
            (next: prev: {
              #### customized packages
              # nixos-unstable pleroma is too far out-of-date for our db
              pleroma = prev.callPackage ./pkgs/pleroma { };
              # jackett doesn't allow customization of the bind address: this will probably always be here.
              jackett = next.callPackage ./pkgs/jackett { pkgs = prev; };
              # fix abrupt HDD poweroffs as during reboot. patching systemd requires rebuilding nearly every package.
              # systemd = import ./pkgs/systemd { pkgs = prev; };

              #### nixos-unstable packages
              # gitea: 1.16.5 contains a fix which makes manual user approval *actually* work.
              # https://github.com/go-gitea/gitea/pull/19119
              # safe to remove after 1.16.5 (or 1.16.7 if we need db compat?)
              gitea = pkgs-gitea.legacyPackages."${system}".gitea;

              # patch rpi uboot with something that fixes USB HDD boot
              ubootRaspberryPi4_64bit = next.callPackage ./pkgs/ubootRaspberryPi4_64bit { pkgs = prev; };
            })
          ];
        };
      }
    );

  };
}

