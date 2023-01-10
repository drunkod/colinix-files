{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-22.11";
  };
  outputs = { self, nixpkgs }:
    let
      patchedPkgsFor = system: nixpkgs.legacyPackages.${system}.applyPatches {
        name = "nixpkgs-patched-uninsane";
        src = nixpkgs;
        patches = import ./list.nix {
          inherit (nixpkgs.legacyPackages.${system}) fetchpatch;
          inherit (nixpkgs.lib) fakeHash;
        };
      };
      patchedFlakeFor = system: import "${patchedPkgsFor system}/flake.nix";
      patchedFlakeOutputsFor = system:
        (patchedFlakeFor system).outputs { inherit self; };
    in
    {
      legacyPackages = builtins.mapAttrs
        (system: _:
          (patchedFlakeOutputsFor system).legacyPackages."${system}"
        )
        nixpkgs.legacyPackages;
    };
}
