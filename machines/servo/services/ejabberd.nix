# docs:
# - <https://docs.ejabberd.im/admin/configuration/basic>
{ lib, ... }:

# TODO: enable
lib.mkIf false {
  sane.impermanence.service-dirs = [
    { user = "ejabberd"; group = "ejabberd"; directory = "/var/lib/ejabberd"; }
  ];
  # TODO: allocate UIDs/GIDs ?
  services.ejabberd.enable = true;
  services.ejabberd.configFile = ./ejabberd.yaml;
}
