{ lib, pkgs, ... }:

{
  # TODO: don't need to depend on binsh if we were to use a nix-style shebang
  system.activationScripts.linkBluetoothKeys = let
    unwrapped = ../../scripts/install-bluetooth;
    install-bluetooth = pkgs.writeShellApplication {
      name = "install-bluetooth";
      runtimeInputs = with pkgs; [ coreutils gnused ];
      text = ''${unwrapped} "$@"'';
    };
  in (lib.stringAfter
    [ "setupSecrets" "binsh" ]
    ''
    ${install-bluetooth}/bin/install-bluetooth /run/secrets/bt
    ''
  );

  # TODO: use a glob, or a list, or something?
  sops.secrets."bt/car" = {
    sopsFile = ../../secrets/universal/bt/car.bin;
    format = "binary";
  };
  sops.secrets."bt/portable-speaker" = {
    sopsFile = ../../secrets/universal/bt/portable-speaker.bin;
    format = "binary";
  };
}
