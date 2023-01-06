{ config, lib, sane-lib, ... }:

let
  path = sane-lib.path;
  cfg = config.sane.persist;

  # take a directory attrset and fix its directory to be absolute
  fixDir = relativeTo: dir: dir // {
    directory = path.concat [ relativeTo dir.directory ];
  };
  fixDirs = relativeTo: dirs: map (fixDir relativeTo) dirs;

  # set the `store` attribute on one dir attrset
  fixStore = store: dir: dir // {
    store = cfg.stores."${store}";
  };
  # String -> [a] -> [a]
  # usually called on an attrset to map (AttrSet [a]) -> [a]
  fixStoreForDirs = store: dirs: map (fixStore store) dirs;

  # populate the `store` attr for all the substores in home
  unfixed-home-dirs = builtins.concatLists (lib.mapAttrsToList fixStoreForDirs cfg.home);
  # populate the `store` attr for all the substores in sys
  unfixed-sys-dirs = builtins.concatLists (lib.mapAttrsToList fixStoreForDirs cfg.sys);

  fixed-dirs = (fixDirs "/home/colin" unfixed-home-dirs) ++ (fixDirs "/" unfixed-sys-dirs);

  dirToAttr = dir: {
    name = dir.directory;
    value = {
      inherit (dir) user group mode store;
    };
  };
in
{
  sane.persist.all = builtins.listToAttrs (map dirToAttr fixed-dirs);
}
