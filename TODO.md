# features/tweaks
- enable sshfs (deskto/lappy)
- set firefox default search engine
- iron out video drivers

# cleanup
- remove helpers from outputs section (use `let .. in`)


# speed up cross compiling
   https://nixos.wiki/wiki/Cross_Compiling
   https://nixos.wiki/wiki/NixOS_on_ARM
   overlays = [{ ... }: {
     nixpkgs.crossSystem.system = "aarch64-linux";
   }];
