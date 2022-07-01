# features/tweaks
- set firefox default search engine
- iron out video drivers
- emoji picker application
- find a Masto/Pleroma app which works on mobile
- set default apps (https://unix.stackexchange.com/a/684582)


# speed up cross compiling
   https://nixos.wiki/wiki/Cross_Compiling
   https://nixos.wiki/wiki/NixOS_on_ARM
   overlays = [{ ... }: {
     nixpkgs.crossSystem.system = "aarch64-linux";
   }];
