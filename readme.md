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
