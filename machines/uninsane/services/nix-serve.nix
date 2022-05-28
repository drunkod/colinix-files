# docs: https://nixos.wiki/wiki/Binary_Cache
# to copy something to this machine's nix cache, do:
#   nix copy --to ssh://nixcache.uninsane.org PACKAGE
{ secrets, ... }:

{
  services.nix-serve = {
    enable = true;
    secretKeyFile = builtins.toFile "nix-serve-priv-key.pem" secrets.nix-serve.cache-priv-key;
    #  "/var/cache-priv-key.pem";
  };
}
