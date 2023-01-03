{ config, lib, ... }:

let
  cfg = config.sane.impermanence;
in
{
  imports = [
    ./crypt.nix
    ./private.nix
  ];

  config = lib.mkIf cfg.enable {
    sane.impermanence.stores."plaintext" = {
      mountpt = "/nix/persist";
    };
  };
}
