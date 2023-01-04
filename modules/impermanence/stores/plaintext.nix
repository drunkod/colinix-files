{ config, lib, ... }:

let
  cfg = config.sane.impermanence;
in lib.mkIf cfg.enable {
  sane.impermanence.stores."plaintext" = {
    origin = "/nix/persist";
  };
  # TODO: needed?
  # sane.fs."/nix".mount = {};
}
