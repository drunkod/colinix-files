to deploy:
```sh
nixos-rebuild --flake "./#servo" {build,switch}
```

more options (like building packages defined in this repo):
```sh
nix flake show
```


## secrets

i use [sops](https://github.com/Mic92/sops-nix) for secrets.
see `modules/universal/secrets.nix` for some tips.

## building images

to build a distributable image (GPT-formatted image with rootfs and /boot partition):
```sh
nix build ./#imgs.lappy
```
this can then be `dd`'d onto a disk and directly booted from a EFI system.
there's some post-processing to do before running a rebuild on the deployed system (deploying ssh keys, optionally changing fs UUIDs, etc).
refer to flake.nix for more details.

