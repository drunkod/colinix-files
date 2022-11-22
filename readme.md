to deploy:

```sh
nixos-rebuild --flake "./#servo" {build,switch}
```

if the target is the same as the host, nix will grab the hostname automatically:

```sh
nixos-rebuild --flake . {build,switch}
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

## building packages

to build one of the custom sane packages, just name it:

```sh
nix build ./#fluffychat-moby
```

to build a nixpkg:

```sh
nix build ./#nixpkgs.curl
```

to build a package for another platform:

```sh
nix build ./#packages.aarch64-linux.nixpkgs.ubootRaspberryPi4_64bit
```

## using this repo in your own config

i try to ensure everything in the `modules/` directory is hidden behind some enable flag or other.
it should be possible to copy that whole directory into your own config, and then selectively
populate what you want (like the impermenance paths, etc).
more practically, a lot of things in there still assume a user named `colin`, so you'll probably
want to patch it for your name -- or just use it as a reference.

## contact

if you want to contact me for questions, or collaborate to split something useful into a shared repo, etc,
you can reach me via any method listed [here](https://uninsane.org/about).
