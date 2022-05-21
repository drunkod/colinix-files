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
      inherit (self.packages.aarch64-linux) pkgs;
      pkgs.unstable = pkgsUnstable;
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
        ./cfg
        ./modules
      ];
    };
    packages = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.all (system:
      {
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
      }
    );
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

