to deploy:

```sh
nixos-rebuild --flake ".#servo" {build,switch}
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
see `hosts/common/secrets.nix` for some tips.

## building images

to build a distributable image (GPT-formatted image with rootfs and /boot partition):
```sh
nix build ./#imgs.lappy
```
this can then be `dd`'d onto a disk and directly booted from a EFI system.
there's some post-processing to do before running a rebuild on the deployed system (deploying ssh keys, optionally changing fs UUIDs, etc).
refer to flake.nix for more details.

## building packages

build anything with
```
nix build .#<pkgname>
```

specifically, i pass the full package closure to the `legacyPackages` flake output. that includes both my own packages and upstream packages.

on the other hand the `packages` output contains only my own packages.

in addition, my packages are placed into both the global scope and a `sane` scope.
so use the scoped path when you want to be explicit.

```
nix build sane.linux-megous
```

## using this repo in your own config

this should be a pretty "standard" flake. just reference it, and import either
- `nixosModules.sane` (for the modules)
- `overlays.pkgs` (for the packages)

`nixosModules.sane` corresponds to everything in the `modules/` directory.
it's a mix of broad and narrow scope options.
e.g. `sane.fs` is a completely standalone thing,
whereas `sane.web-browser` is highly personalized and doesn't *really* make sense to export.
regardless of scope, i do try to ensure that everything in `modules/` is hidden behind some enable flag
so that the disorganization isn't that critical.

## contact

if you want to contact me for questions, or collaborate to split something useful into a shared repo, etc,
you can reach me via any method listed [here](https://uninsane.org/about).
