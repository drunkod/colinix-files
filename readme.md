after checking out, drop secrets into secrets/

to build:
```sh
nixos-rebuild --flake "/etc/nixos/#uninsane" {build,switch}
```

query with:
```sh
nix flake show
```
