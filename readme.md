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
nix build .#lappy-gpt
```
this can then be `dd`'d onto a disk and directly booted from a EFI system.
there's some post-processing to do before running a rebuild on the deployed system (e.g. change fstab UUIDs)
refer to flake.nix for more details
