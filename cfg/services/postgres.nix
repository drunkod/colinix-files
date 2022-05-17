{ config, pkgs, lib, ... }:

{
  services.postgresql.enable = true;
  services.postgresql.dataDir = "/opt/postgresql/13";
  # XXX colin: for a proper deploy, we'd want to include something for Pleroma here too.
  # services.postgresql.initialScript = pkgs.writeText "synapse-init.sql" ''
  #   CREATE ROLE "matrix-synapse" WITH LOGIN PASSWORD '<password goes here>';
  #   CREATE DATABASE "matrix-synapse" WITH OWNER "matrix-synapse"
  #     TEMPLATE template0
  #     ENCODING = "UTF8"
  #     LC_COLLATE = "C"
  #     LC_CTYPE = "C";
  # '';


  # common admin operations:
  #   sudo -u postgres psql
  #   > \l   # lists all databases
  #   > \du  # lists all roles
  #   > \q   # exits psql
}
