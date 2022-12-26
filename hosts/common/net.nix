{ config, lib, pkgs, ... }:

{
  # if using router's DNS, these mappings will already exist.
  # if using a different DNS provider (which servo does), then we need to explicity provide them.
  # ugly hack. would be better to get servo to somehow use the router's DNS
  networking.hosts = {
    "192.168.0.5" = [ "servo" ];
    "192.168.0.20" = [ "lappy" ];
    "192.168.0.22" = [ "desko" ];
    "192.168.0.48" = [ "moby" ];
  };

  # the default backend is "wpa_supplicant".
  # wpa_supplicant reliably picks weak APs to connect to.
  # see: <https://gitlab.freedesktop.org/NetworkManager/NetworkManager/-/issues/474>
  # iwd is an alternative that shouldn't have this problem
  # docs:
  # - <https://nixos.wiki/wiki/Iwd>
  # - <https://iwd.wiki.kernel.org/networkmanager>
  # - `man iwd.config`  for global config
  # - `man iwd.network` for per-SSID config
  # use `iwctl` to control
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd.enable = true;
  networking.wireless.iwd.settings = {
    # auto-connect to a stronger network if signal drops below this value
    # bedroom -> bedroom connection is -35 to -40 dBm
    # bedroom -> living room connection is -60 dBm
    General.RoamThreshold = "-52";  # default -70
    General.RoamThreshold5G = "-52";  # default -76
  };

  # TODO: don't need to depend on binsh if we were to use a nix-style shebang
  system.activationScripts.linkIwdKeys = let
    unwrapped = ../../scripts/install-iwd;
    install-iwd = pkgs.writeShellApplication {
      name = "install-iwd";
      runtimeInputs = with pkgs; [ coreutils gnused ];
      text = ''${unwrapped} "$@"'';
    };
  in (lib.stringAfter
    [ "setupSecrets" "binsh" ]
    ''
    mkdir -p /var/lib/iwd
    ${install-iwd}/bin/install-iwd /run/secrets/iwd /var/lib/iwd
    ''
  );
}
