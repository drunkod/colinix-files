# docs:
# - <https://nixos.wiki/wiki/Flakes>
# - <https://serokell.io/blog/practical-nix-flakes>

{
  inputs = {
    nixpkgs-stable.url = "nixpkgs/nixos-22.11";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    mobile-nixos = {
      url = "github:nixos/mobile-nixos";
      flake = false;
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-22.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    uninsane = {
      url = "git+https://git.uninsane.org/colin/uninsane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    mobile-nixos,
    home-manager,
    sops-nix,
    impermanence,
    uninsane
  }: let
    patchedPkgs = system: nixpkgs.legacyPackages.${system}.applyPatches {
      name = "nixpkgs-patched-uninsane";
      src = nixpkgs;
      patches = import ./nixpatches/list.nix nixpkgs.legacyPackages.${system}.fetchpatch;
    };
    # return something which behaves like `pkgs`, for the provided system
    # `local` = architecture of builder. `target` = architecture of the system beying deployed to
    nixpkgsFor = local: target: import (patchedPkgs target) { crossSystem = target; localSystem = local; };
    # evaluate ONLY our overlay, for the provided system
    customPackagesFor = local: target: import ./pkgs/overlay.nix (nixpkgsFor local target) (nixpkgsFor local target);
    decl-host = { name, local, target }:
    let
      nixosSystem = import ((patchedPkgs target) + "/nixos/lib/eval-config.nix");
    in (nixosSystem {
      # by default the local system is the same as the target, employing emulation when they differ
      system = target;
      specialArgs = { inherit mobile-nixos home-manager impermanence; };
      modules = [
        ./modules
        (import ./hosts/instantiate.nix name)
        home-manager.nixosModule
        impermanence.nixosModule
        sops-nix.nixosModules.sops
        {
          nixpkgs.overlays = [
            (import "${mobile-nixos}/overlay/overlay.nix")
            uninsane.overlay
            (import ./pkgs/overlay.nix)
            (next: prev: rec {
              # non-emulated packages build *from* local *for* target.
              # for large packages like the linux kernel which are expensive to build under emulation,
              # the config can explicitly pull such packages from `pkgs.cross` to do more efficient cross-compilation.
              cross = (nixpkgsFor local target) // (customPackagesFor local target);
              stable = import nixpkgs-stable { system = target; };

              # cross-compatible packages
              # gocryptfs = cross.gocryptfs;

              # pinned packages:
              # 2022/12/13: grpc does not build on aarch64-linux. https://github.com/NixOS/nixpkgs/issues/205887
              grpc = stable.grpc;
              # depends on grpc, so pinned.
              duplicity = stable.duplicity;
            })
          ];
        }
      ];
    });

    decl-bootable-host = { name, local, target }: rec {
      nixosConfiguration = decl-host { inherit name local target; };
      # this produces a EFI-bootable .img file (GPT with a /boot partition and a system (/ or /nix) partition).
      # after building this:
      #   - flash it to a bootable medium (SD card, flash drive, HDD)
      #   - resize the root partition (use cfdisk)
      #   - mount the part
      #      - chown root:nixbld <part>/nix/store
      #      - chown root:root -R <part>/nix/store/*
      #      - chown root:root -R <part>/persist  # if using impermanence
      #      - populate any important things (persist/, home/colin/.ssh, etc)
      #   - boot
      #   - if fs wasn't resized automatically, then `sudo btrfs filesystem resize max /`
      #   - checkout this flake into /etc/nixos AND UPDATE THE FS UUIDS.
      #   - `nixos-rebuild --flake './#<host>' switch`
      img = nixosConfiguration.config.system.build.img;
    };
    hosts.servo = decl-bootable-host { name = "servo"; local = "x86_64-linux"; target = "x86_64-linux"; };
    hosts.desko = decl-bootable-host { name = "desko"; local = "x86_64-linux"; target = "x86_64-linux"; };
    hosts.lappy = decl-bootable-host { name = "lappy"; local = "x86_64-linux"; target = "x86_64-linux"; };
    hosts.moby = decl-bootable-host { name = "moby"; local = "aarch64-linux"; target = "aarch64-linux"; };
    # special cross-compiled variant, to speed up deploys from an x86 box to the arm target
    # note that these *do* produce different store paths, because the closure for the tools used to cross compile
    # v.s. emulate differ.
    # so deploying foo-cross and then foo incurs some rebuilding.
    hosts.moby-cross = decl-bootable-host { name = "moby"; local = "x86_64-linux"; target = "aarch64-linux"; };
    hosts.rescue = decl-bootable-host { name = "rescue"; local = "x86_64-linux"; target = "x86_64-linux"; };
  in {
    nixosConfigurations = builtins.mapAttrs (name: value: value.nixosConfiguration) hosts;
    imgs = builtins.mapAttrs (name: value: value.img) hosts;
    packages = let
      allPkgsFor = sys: (customPackagesFor sys sys) // {
        nixpkgs = nixpkgsFor sys sys;
        uninsane = uninsane.packages."${sys}";
      };
    in {
      x86_64-linux = allPkgsFor "x86_64-linux";
      aarch64-linux = allPkgsFor "aarch64-linux";
    };
    templates = {
      python-data = {
        # initialize with:
        # - `nix flake init -t '/home/colin/dev/nixos/#python-data'`
        # then enter with:
        # - `nix develop`
        path = ./templates/python-data;
        description = "python environment for data processing";
      };
    };
  };
}

