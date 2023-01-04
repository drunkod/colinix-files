{ config, lib, sane-lib, ... }:

let
  cfg = config.sane.impermanence;
  path = sane-lib.path;
in
{
  imports = [
    ./crypt.nix
    ./plaintext.nix
    ./private.nix
  ];

  config = lib.mkIf cfg.enable {
    # make sure that the store has the same acl as the main filesystem,
    # particularly for /home/colin.
    #
    # N.B.: we have a similar problem with all mounts:
    # <crypt>/.cache/mozilla won't inherit <plain>/.cache perms.
    # this is less of a problem though, since we don't really support overlapping mounts like that in the first place.
    # what is a problem is if the user specified some other dir we don't know about here.
    # like "/var", and then "/nix/persist/var" has different perms and something mounts funny.
    # TODO: just add assertions that sane.fs."${backing}/${dest}".dir == sane.fs."${dest}" for each mount point?
    sane.fs = lib.mapAttrs' (_name: store: let
      home-in-store = path.from store.prefix "/home/colin";
    in {
      name = path.concat [ store.origin home-in-store ];
      value.dir.acl = config.sane.fs."/home/colin".generated.acl;
    }) cfg.stores;
  };
}
