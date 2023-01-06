{ config, lib, sane-lib, ... }:

let
  path = sane-lib.path;
  cfg = config.sane.persist;
  mapDirs = relativeTo: store: dirs: (map
    (d: {
      inherit (d) user group mode;
      directory = path.concat [ relativeTo d.directory ];
      store = cfg.stores."${store}";
    })
    dirs
  );
  mapDirSets = relativeTo: dirsSubOptions: let
    # list where each elem is a list from calling mapDirs on one store at a time
    contextFreeDirSets = lib.mapAttrsToList (mapDirs relativeTo) dirsSubOptions;
  in
    builtins.concatLists contextFreeDirSets;
in
{
  sane.persist.all = (mapDirSets "/home/colin" cfg.home) ++ (mapDirSets "/" cfg.sys);
}
