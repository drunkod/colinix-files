{ config, lib, ... }:

let
  cfg = config.sane.impermanence;
in
{
  imports = [
    ./crypt.nix
    ./plaintext.nix
    ./private.nix
  ];

  config = lib.mkIf cfg.enable {
  };
}
