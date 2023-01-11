# docs:
# - <https://nixos.wiki/wiki/Flakes>
# - <https://serokell.io/blog/practical-nix-flakes>

{
  inputs = {
    nixpkgs-stable.url = "nixpkgs/nixos-22.11";
    nixpkgs-unpatched.url = "nixpkgs/nixos-unstable";
    nixpkgs = {
      url = "path:nixpatches";
      inputs.nixpkgs.follows = "nixpkgs-unpatched";
    };
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
    uninsane-dot-org = {
      url = "git+https://git.uninsane.org/colin/uninsane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-unpatched,
    mobile-nixos,
    home-manager,
    sops-nix,
    uninsane-dot-org
  }:
    let
      nixpkgsCompiledBy = local: nixpkgs.legacyPackages."${local}";

      evalHost = { name, local, target }:
        let
          # XXX: we'd prefer to use `nixosSystem = (nixpkgsCompiledBy local).nixos`
          # but it doesn't propagate config to the underlying pkgs, meaning it doesn't let you use
          # non-free packages even after setting nixpkgs.allowUnfree.
          nixosSystem = import ((nixpkgsCompiledBy local).path + "/nixos/lib/eval-config.nix");
        in
          (nixosSystem {
            # we use pkgs built for and *by* the target, i.e. emulation, by default.
            # cross compilation only happens on explicit access to `pkgs.cross`
            system = target;
            modules = [
              (import ./hosts/instantiate.nix { localSystem = local; hostName = name; })
              self.nixosModules.default
              self.nixosModules.passthru
              {
                nixpkgs.overlays = [
                  self.overlays.default
                  self.overlays.passthru
                ];
              }
            ];
          });
    in {
      nixosConfigurations = {
        servo = evalHost { name = "servo"; local = "x86_64-linux"; target = "x86_64-linux"; };
        desko = evalHost { name = "desko"; local = "x86_64-linux"; target = "x86_64-linux"; };
        lappy = evalHost { name = "lappy"; local = "x86_64-linux"; target = "x86_64-linux"; };
        moby = evalHost { name = "moby"; local = "aarch64-linux"; target = "aarch64-linux"; };
        # special cross-compiled variant, to speed up deploys from an x86 box to the arm target
        # note that these *do* produce different store paths, because the closure for the tools used to cross compile
        # v.s. emulate differ.
        # so deploying foo-cross and then foo incurs some rebuilding.
        moby-cross = evalHost { name = "moby"; local = "x86_64-linux"; target = "aarch64-linux"; };
        rescue = evalHost { name = "rescue"; local = "x86_64-linux"; target = "x86_64-linux"; };
      };

      # unofficial output
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
      imgs = builtins.mapAttrs (_: host-dfn: host-dfn.config.system.build.img) self.nixosConfigurations;

      overlays = rec {
        default = pkgs;
        pkgs = import ./pkgs/overlay.nix;
        passthru =
          let
            stable = next: prev: {
              stable = nixpkgs-stable.legacyPackages."${prev.stdenv.hostPlatform}";
            };
            mobile = (import "${mobile-nixos}/overlay/overlay.nix");
            uninsane = uninsane-dot-org.overlay;
          in
          next: prev:
            (stable next prev) // (mobile next prev) // (uninsane next prev);
      };

      nixosModules = rec {
        default = sane;
        sane = import ./modules;
        passthru = { ... }: {
          imports = [
            home-manager.nixosModule
            sops-nix.nixosModules.sops
          ];
        };
      };

      # this includes both our native packages and all the nixpkgs packages.
      legacyPackages =
        let
          allPkgsFor = sys: (nixpkgsCompiledBy sys).appendOverlays [
            self.overlays.passthru self.overlays.pkgs
          ];
        in {
          x86_64-linux = allPkgsFor "x86_64-linux";
          aarch64-linux = allPkgsFor "aarch64-linux";
        };

      # extract only our own packages from the full set
      packages = builtins.mapAttrs
        (_: full: full.sane // { inherit (full) sane uninsane-dot-org; })
        self.legacyPackages;

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

