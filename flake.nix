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
    pkgs-unstable.url = "nixpkgs/nixos-unstable";
    pkgs-gitea.url = "nixpkgs/c777cdf5c564015d5f63b09cc93bef4178b19b01";
    # pkgs-telegram.url = "nixpkgs/33775ec9a2173a08e46edf9f46c9febadbf743e8";# 2022/04/18; telegram 3.7.3. fails: nix log /nix/store/y5kv47hnv55qknb6cnmpcyraicay79fx-telegram-desktop-3.7.3.drv: g++: fatal error: cannot execute '/nix/store/njk5sbd21305bhr7gwibxbbvgbx5lxvn-gcc-9.3.0/libexec/gcc/aarch64-unknown-linux-gnu/9.3.0/cc1plus': execv: No such file or directory
    # pkgs-mobile.url = "nixpkgs/6daa4a5c045d40e6eae60a3b6e427e8700f1c07f";  # FAILS: currently pinned to mobile-nixos tip  -> fails building lvgui
    # pkgs-mobile.url = "nixpkgs/7e567a3d092b7de69cdf5deaeb8d9526de230916";  # WORKS (NO PHOSH): 2021/06/21, coordinated with mobile-nixos 85557dca93ae574eaa7dc7b1877edf681a280d35
    pkgs-mobile.url = "nixpkgs/dfd82985c273aac6eced03625f454b334daae2e8";    # WORKS: 2022/05/20; mobile-nixos follows this same commit.
    # pkgs-mobile.url = "nixpkgs/ff691ed9ba21528c1b4e034f36a04027e4522c58";  # FAILS (kernelAtLeast) 2022/05/17  https://hydra.nixos.org/eval/1762140
    # pkgs-mobile.url = "nixpkgs/710fed5a2483f945b14f4a58af2cd3676b42d8c8";  # BUILDS (NO PHOSH) 2022/03/30  https://hydra.nixos.org/eval/1752121
    # pkgs-mobile.url = "nixpkgs/cbe587c735b734405f56803e267820ee1559e6c1";  # UNTESTED: successful mobile-nixos build https://hydra.nixos.org/eval/1759474#tabs-inputs
    # pkgs-mobile.url = "nixpkgs/48037fd90426e44e4bf03e6479e88a11453b9b66";  # UNTESTED: successful mobile-nixos build 2022/05/19 https://hydra.nixos.org/eval/1762659#tabs-inputs
    # pkgs-mobile.url = "nixpkgs/1d7db1b9e4cf1ee075a9f52e5c36f7b9f4207502"; 
    # pkgs-mobile.url = "nixpkgs/43ff6cb1c027d13dc938b88eb099462210fea52f";
    # pkgs-mobile.url = "nixpkgs/98bb5b77c8c6666824a4c13d23befa1e07210ef1";  # FAILS: mobile-nixos build 2022/02/10 https://hydra.nixos.org/eval/1743260#tabs-inputs fails building lvgui
    # pkgs-mobile.url = "nixpkgs/nixos-21.11";                               # FAILS: linux fails at config time
    # pkgs-mobile.url = "nixpkgs/5aaed40d22f0d9376330b6fa413223435ad6fee5";  # UNTESTED (NO PHOSH): associated with HN comment 2022/01/16 https://hydra.nixos.org/build/164693256#tabs-buildinputs
    # pkgs-mobile.url = "nixpkgs/23d785aa6f853e6cf3430119811c334025bbef55";  # FAILS: latest mobile-nixos:unstable:device.pine64-pinephone.aarch64-linux build 2022/02/20 https://hydra.nixos.org/build/167888996#tabs-buildinputs  -- fails building lvgui
    mobile-nixos = {
      # this includes a patch to enable flake support
      # url = "github:ngi-nix/mobile-nixos/afe022e1898aa05381077a89c3681784e6074458";
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

  outputs = { self, nixpkgs, pkgs-unstable, pkgs-gitea, pkgs-mobile, mobile-nixos, home-manager, nurpkgs }: {
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
        specialArgs = { inherit home-manager; inherit nurpkgs; secrets = import ./secrets.nix ;};
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
          # gitea: 1.16.5 contains a fix which makes manual user approval *actually* work.
          # https://github.com/go-gitea/gitea/pull/19119
          # safe to remove after 1.16.5 (or 1.16.7 if we need db compat?)
          gitea = pkgs-gitea.legacyPackages.${system}.gitea;

          # nixos-21.11 whalebird uses an insecure electron version.
          # TODO: remove this on next nixos release.
          whalebird = pkgs-unstable.legacyPackages.${system}.whalebird;

          # pkgs-mobile' telegram doesn't build, so explicitly use the stable one.
          # TODO: apply this specifically to the moby build?
          # tdesktop = pkgs-telegram.legacyPackages.${system}.tdesktop;
          tdesktop = nixpkgs.legacyPackages.${system}.tdesktop;
        })
      ];
    };
  };
}

