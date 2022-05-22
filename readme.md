after checking out, drop secrets into secrets/

to build:
```sh
nixos-rebuild --flake "/etc/nixos/#uninsane" {build,switch}
```

query with:
```sh
nix flake show
```


# secrets
change files in secrets/. they need to be checked into git with some placeholder text for them to be exposed to the flake,
but after that you can set them to their real value and run `git update-index --assume-unchanged secrets/*`

## building images

to build a distributable image (MBR-formatted image with nothing on the first part and only /nix on the second part), use `nix build`:
```sh
nix build "/etc/nixos/#nixosConfigurations.lappy-sd.config.system.build.sdImage"
```

to build a distributable image (MBR-formatted ISO with the nix store as a squashfs), use `nix build`:
```sh
nix build "/etc/nixos/#nixosConfigurations.lappy-iso.config.system.build.isoImage"
```

alternatively, boot into a bare NixOS image and run
```sh
NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixpkgs-unstable.tar.gz nix-shell -p nixos-generators --run "nixos-generate --flake /etc/nixos/#lappy --format raw-efi"
```

or
```sh
nix build .#lappy-gpt
```
