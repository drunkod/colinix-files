# features/tweaks
- set firefox default search engine
- iron out video drivers
- emoji picker application
- emoji font (Font Awesome) for sway status bar
- find a Masto/Pleroma app which works on mobile

# cleanup
- remove helpers from outputs section (use `let .. in`)
- port helpers/ to the module system and mkOption


# speed up cross compiling
   https://nixos.wiki/wiki/Cross_Compiling
   https://nixos.wiki/wiki/NixOS_on_ARM
   overlays = [{ ... }: {
     nixpkgs.crossSystem.system = "aarch64-linux";
   }];

# better secrets management? read:
- decrypted at activation time: https://github.com/Mic92/sops-nix
less promising:
- https://christine.website/blog/nixos-encrypted-secrets-2021-01-20
- git-crypt (https://github.com/bobbbay/dotfiles.git)
