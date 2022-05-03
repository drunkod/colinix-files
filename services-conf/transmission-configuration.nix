{ config, pkgs, lib, ... }:

{
  # services.transmission.enable = true;
  services.transmission.settings = {
    rpc-bind-address = "0.0.0.0";
    rpc-host-whitelist = "bt.uninsane.org";
    # rpc-whitelist = "*.*.*.*";
  };
}

