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
  # use `iwctl` to control
  networking.wireless.iwd.enable = true;
  networking.networkmanager.wifi.backend = "iwd";

  system.activationScripts.linkIwdKeys = let
    unwrapped = ../../scripts/install-iwd;
    install-iwd = pkgs.writeShellApplication {
      name = "install-iwd";
      runtimeInputs = with pkgs; [ coreutils gnused ];
      text = ''${unwrapped} "$@"'';
    };
  in (lib.stringAfter
    [ "setupSecrets" ]
    ''
    mkdir -p /var/lib/iwd
    ${install-iwd}/bin/install-iwd /run/secrets/iwd /var/lib/iwd
    ''
  );

  # TODO: use a glob, or a list, or something?
  sops.secrets."iwd/community-university.psk" = {
    sopsFile = ../../secrets/universal/net/community-university.psk.bin;
    format = "binary";
  };
  sops.secrets."iwd/friend-libertarian-dod.psk" = {
    sopsFile = ../../secrets/universal/net/friend-libertarian-dod.psk.bin;
    format = "binary";
  };
  sops.secrets."iwd/friend-rationalist-empathist.psk" = {
    sopsFile = ../../secrets/universal/net/friend-rationalist-empathist.psk.bin;
    format = "binary";
  };
  sops.secrets."iwd/home-bedroom.psk" = {
    sopsFile = ../../secrets/universal/net/home-bedroom.psk.bin;
    format = "binary";
  };
  sops.secrets."iwd/home-shared-24G.psk" = {
    sopsFile = ../../secrets/universal/net/home-shared-24G.psk.bin;
    format = "binary";
  };
  sops.secrets."iwd/home-shared.psk" = {
    sopsFile = ../../secrets/universal/net/home-shared.psk.bin;
    format = "binary";
  };
  sops.secrets."iwd/iphone" = {
    sopsFile = ../../secrets/universal/net/iphone.psk.bin;
    format = "binary";
  };
}
