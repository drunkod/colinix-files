# docs:
#   https://nixos.wiki/wiki/Flakes
#   https://serokell.io/blog/practical-nix-flakes

{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.05";
    mobile-nixos = {
      url = "github:nixos/mobile-nixos";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix.url = "github:Mic92/sops-nix";
    impermanence.url = "github:nix-community/impermanence";
  };

  outputs = { self, nixpkgs, mobile-nixos, home-manager, sops-nix, impermanence }:
  let
    patchedPkgs = system: nixpkgs.legacyPackages.${system}.applyPatches {
      name = "nixpkgs-patched-uninsane";
      src = nixpkgs;
      patches = import ./nixpatches/list.nix nixpkgs.legacyPackages.${system}.fetchpatch;
    };
    # return something which behaves like `pkgs`, for the provided system
    nixpkgsFor = system: import (patchedPkgs system) { inherit system; };
    # evaluate ONLY our overlay, for the provided system
    customPackagesFor = system: import ./pkgs/overlay.nix (nixpkgsFor system) (nixpkgsFor system);
    decl-machine = { name, system }:
    let
      nixosSystem = import ((patchedPkgs system) + "/nixos/lib/eval-config.nix");
    in (nixosSystem {
      inherit system;
      specialArgs = { inherit nixpkgs mobile-nixos home-manager impermanence; };
      modules = [
        ./modules
        ./machines/${name}
        (import ./helpers/set-hostname.nix name)
        home-manager.nixosModule
        impermanence.nixosModule
        sops-nix.nixosModules.sops
        {
          nixpkgs.config.allowUnfree = true;
          nixpkgs.overlays = [
            (import "${mobile-nixos}/overlay/overlay.nix")
            (import ./pkgs/overlay.nix)
          ];
        }
      ];
    });

    decl-bootable-machine = { name, system }: rec {
      nixosConfiguration = decl-machine { inherit name system; };
      # this produces a EFI-bootable .img file (GPT with a /boot partition and a system (/ or /nix) partition).
      # after building this:
      #   - flash it to a bootable medium (SD card, flash drive, HDD)
      #   - resize the root partition (use cfdisk)
      #   - mount the part
      #     chown root:nixblkd <part>/nix/store
      #     chmod 775 <part>/nix/store
      #     chown root:root -R <part>/nix/store/*
      #     populate any important things (persist/, home/colin/.ssh, etc)
      #   - boot
      #   - if fs wasn't resized automatically, then `sudo btrfs filesystem resize max /`
      #   - checkout this flake into /etc/nixos AND UPDATE THE FS UUIDS.
      #   - `nixos-rebuild --flake './#<machine>' switch`
      img = nixosConfiguration.config.system.build.img;
    };
    machines.servo = decl-bootable-machine { name = "servo"; system = "aarch64-linux"; };
    machines.desko = decl-bootable-machine { name = "desko"; system = "x86_64-linux"; };
    machines.lappy = decl-bootable-machine { name = "lappy"; system = "x86_64-linux"; };
    machines.moby = decl-bootable-machine { name = "moby"; system = "aarch64-linux"; };
    machines.rescue = decl-bootable-machine { name = "rescue"; system = "x86_64-linux"; };
  in {
    nixosConfigurations = builtins.mapAttrs (name: value: value.nixosConfiguration) machines;
    imgs = builtins.mapAttrs (name: value: value.img) machines;
    packages.x86_64-linux = customPackagesFor "x86_64-linux";
    packages.aarch64-linux = customPackagesFor "aarch64-linux";
  };
}

