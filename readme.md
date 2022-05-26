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

to build a distributable image (GPT-formatted image with rootfs and /boot partition):
```sh
nix build .#imgs.lappy
```
this can then be `dd`'d onto a disk and directly booted from a EFI system.
there's some post-processing to do before running a rebuild on the deployed system (e.g. change fstab UUIDs)
refer to flake.nix for more details


# admin tips

online: <https://nixos.wiki/wiki/Cheatsheet>

verify ALL nix store contents with:
```sh
sudo nix-store --verify --check-contents  # add the --repair flag to auto-repair as well
```

search for a package with:
```sh
nix search nixpkgs <query string>
```

find which package owns some file with:
```sh
nix-locate /bin/vim  # or any other package-relative path
```
