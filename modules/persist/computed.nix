{ config, lib, sane-lib, ... }:

let
  path = sane-lib.path;
  cfg = config.sane.persist;

  withPrefix = relativeTo: entries: lib.mapAttrs' (fspath: value: {
    name = path.concat [ relativeTo fspath ];
    inherit value;
  }) entries;
in
{
  # merge the `byPath` mappings from both `home` and `sys` into one namespace
  sane.persist.byPath = lib.mkMerge [
    (withPrefix "/home/colin" cfg.home.byPath)
    (withPrefix "/" cfg.sys.byPath)
  ];
}
