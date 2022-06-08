# docs: https://nixos.wiki/wiki/Binary_Cache
# to copy something to this machine's nix cache, do:
#   nix copy --to ssh://nixcache.uninsane.org PACKAGE
{ config, ... }:

{
  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets.nix_serve_privkey.path;
  };

  sops.secrets.nix_serve_privkey = {
    sopsFile = ../../../secrets/uninsane.yaml;
  };
}
