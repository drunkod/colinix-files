# docs:
#   https://nixos.wiki/wiki/Flakes
#   https://serokell.io/blog/practical-nix-flakes

{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
    pkgs-unstable.url = "nixpkgs/nixos-unstable";
    # pkgs-telegram.url = "nixpkgs/33775ec9a2173a08e46edf9f46c9febadbf743e8";# 2022/04/18; telegram 3.7.3. fails: nix log /nix/store/y5kv47hnv55qknb6cnmpcyraicay79fx-telegram-desktop-3.7.3.drv: g++: fatal error: cannot execute '/nix/store/njk5sbd21305bhr7gwibxbbvgbx5lxvn-gcc-9.3.0/libexec/gcc/aarch64-unknown-linux-gnu/9.3.0/cc1plus': execv: No such file or directory
    pkgs-mobile.url = "nixpkgs/dfd82985c273aac6eced03625f454b334daae2e8";    # WORKS: 2022/05/20; mobile-nixos follows this same commit.
    mobile-nixos = {
      url = "github:nixos/mobile-nixos";
      flake = false;
      # TODO colin: is this necessary (or wanted)?
      # inputs.nixpkgs.follows = "pkgs-mobile";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-21.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nurpkgs.url = "github:nix-community/NUR";
  };

  outputs = { self, nixpkgs, pkgs-unstable, pkgs-mobile, mobile-nixos, home-manager, nurpkgs }: {
    machines.uninsane = self.decl-bootable-machine { name = "uninsane"; system = "aarch64-linux"; };
    machines.desko = self.decl-bootable-machine { name = "desko"; system = "x86_64-linux"; };
    machines.lappy = self.decl-bootable-machine { name = "lappy"; system = "x86_64-linux"; };

    machines.moby =
      let machine = self.decl-machine {
        name = "moby";
        system = "aarch64-linux";
        extraModules = [
          (import "${mobile-nixos}/lib/configuration.nix" {
            device = "pine64-pinephone";
          })
        ];
        basePkgs = pkgs-mobile;
      };
      in {
        nixosConfiguration = machine;
        img = machine.config.mobile.outputs.u-boot.disk-image;
      };

    nixosConfigurations = builtins.mapAttrs (name: value: value.nixosConfiguration) self.machines;
    imgs = builtins.mapAttrs (name: value: value.img) self.machines;

    decl-machine = { name, system, extraModules ? [], basePkgs ? nixpkgs }: (basePkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit home-manager; inherit nurpkgs; secrets = import ./secrets/default.nix; };
        modules = [
          ./configuration.nix
          ./modules
          ./machines/${name}
          (import ./helpers/set-hostname.nix name)
          (self.overlaysModule system)
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

    overlaysModule = system: { config, pkgs, ...}: {
      nixpkgs.config.allowUnfree = true;

      nixpkgs.overlays = [
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

          # patch rpi uboot with something that fixes USB HDD boot
          ubootRaspberryPi4_64bit = next.callPackage ./pkgs/ubootRaspberryPi4_64bit { pkgs = prev; };

          # we care about keeping these packages up-to-date
          electrum = pkgs-unstable.legacyPackages.${system}.electrum;

          #### TEMPORARY NIXOS-UNSTABLE PACKAGES

          # pkgs-mobile' telegram doesn't build, so explicitly use the stable one.
          # TODO: apply this specifically to the moby build?
          # tdesktop = pkgs-telegram.legacyPackages.${system}.tdesktop;
          tdesktop = nixpkgs.legacyPackages.${system}.tdesktop;
        })
      ];
    };
  };
}

