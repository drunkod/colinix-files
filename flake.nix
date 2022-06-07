# docs:
#   https://nixos.wiki/wiki/Flakes
#   https://serokell.io/blog/practical-nix-flakes

{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
    # pkgs-telegram.url = "nixpkgs/33775ec9a2173a08e46edf9f46c9febadbf743e8";# 2022/04/18; telegram 3.7.3. fails: nix log /nix/store/y5kv47hnv55qknb6cnmpcyraicay79fx-telegram-desktop-3.7.3.drv: g++: fatal error: cannot execute '/nix/store/njk5sbd21305bhr7gwibxbbvgbx5lxvn-gcc-9.3.0/libexec/gcc/aarch64-unknown-linux-gnu/9.3.0/cc1plus': execv: No such file or directory
    mobile-nixos = {
      url = "github:nixos/mobile-nixos";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nurpkgs.url = "github:nix-community/NUR";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, mobile-nixos, home-manager, nurpkgs, sops-nix }: {
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
      };
      in {
        nixosConfiguration = machine;
        img = machine.config.mobile.outputs.u-boot.disk-image;
      };

    nixosConfigurations = builtins.mapAttrs (name: value: value.nixosConfiguration) self.machines;
    imgs = builtins.mapAttrs (name: value: value.img) self.machines;

    decl-machine = { name, system, extraModules ? [], basePkgs ? nixpkgs }: let
      patchedPkgs = basePkgs.legacyPackages.${system}.applyPatches {
        name = "nixpkgs-patched-uninsane";
        src = basePkgs;
        patches = [
          # phosh: allow fractional scaling
          (basePkgs.legacyPackages.${system}.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/pull/175872.diff";
            sha256 = "sha256-mEmqhe8DqlyCxkFWQKQZu+2duz69nOkTANh9TcjEOdY=";
          })
          # for raspberry pi: allow building u-boot for rpi 4{,00}
          # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
          ./nixpatches/02-rpi4-uboot.patch
          # alternative to https://github.com/NixOS/nixpkgs/pull/173200
          ./nixpatches/04-dart-2.7.0.patch
          # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176476
          ./nixpatches/06-whalebird-4.6.0-aarch64.patch
          # TODO: upstream
          ./nixpatches/07-duplicity-rich-url.patch
        ];
      };
      nixosSystem = import (patchedPkgs + "/nixos/lib/eval-config.nix");
      in (nixosSystem {
        inherit system;
        specialArgs = { inherit home-manager; inherit nurpkgs; secrets = import ./secrets/default.nix; };
        modules = [
          ./configuration.nix
          ./modules
          ./machines/${name}
          (import ./helpers/set-hostname.nix name)
          (self.overlaysModule system)
          sops-nix.nixosModules.sops
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

          #### TEMPORARY NIXOS-UNSTABLE PACKAGES

          # stable telegram doesn't build, so explicitly use the stable one.
          # TODO: apply this specifically to the moby build?
          # tdesktop = pkgs-telegram.legacyPackages.${system}.tdesktop;
          tdesktop = nixpkgs.legacyPackages.${system}.tdesktop;

          #### TEMPORARY: PACKAGES WAITING TO BE UPSTREAMED
          # whalebird = prev.callPackage ./pkgs/whalebird { };
          kaiteki = prev.callPackage ./pkgs/kaiteki { };
        })
      ];
    };
  };
}

