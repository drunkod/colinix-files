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
}
