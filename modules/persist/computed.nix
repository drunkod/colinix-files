{ config, ... }:

let
  cfg = config.sane.persist;
in
{
  sane.persist.byPath = cfg.sys.byPath;
}
