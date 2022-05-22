{ home-manager, config, pkgs, ... }:
{
  imports = [ ./homes.nix ./users.nix ./hardware.nix ];
}
