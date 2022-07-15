# features/tweaks
- emoji picker application
- find a Masto/Pleroma app which works on mobile
- remove hardcoded uid/gids outside of allocations.nix (used in impermanence code -- replace with username/groupname)


# speed up cross compiling
   https://nixos.wiki/wiki/Cross_Compiling
   https://nixos.wiki/wiki/NixOS_on_ARM
   overlays = [{ ... }: {
     nixpkgs.crossSystem.system = "aarch64-linux";
   }];
