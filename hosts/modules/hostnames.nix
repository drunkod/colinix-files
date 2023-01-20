{ config, lib, ... }:

{
  # if using router's DNS, these mappings will already exist.
  # if using a different DNS provider (which servo does), then we need to explicity provide them.
  # ugly hack. would be better to get servo to somehow use the router's DNS
  networking.hosts = lib.mapAttrs' (host: cfg: {
    name = cfg.lan-ip;
    value = [ host ];
  }) config.sane.hosts.by-name;
}
