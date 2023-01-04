{ config, lib, ... }:

let
  cfg = config.sane.impermanence;
in lib.mkIf cfg.enable {
  sane.impermanence.stores."plaintext" = {
    mountpt = "/nix/persist";
  };
  # TODO: needed?
  # sane.fs."/nix".mount = {};
}
