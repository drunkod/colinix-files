# borrows from:
#   https://xeiaso.net/blog/paranoid-nixos-2021-07-18
#   https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/
#   https://github.com/nix-community/impermanence
{ lib, config, impermanence, ... }:

with lib;
let
  cfg = config.colinsane.impermanence;
in
{
  imports = [
    impermanence.nixosModule
  ];
  options = {
    colinsane.impermanence.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = mkIf cfg.enable {
    environment.persistence."/nix/persist" = {
      directories = [
        # TODO: more granular persistence of /home
        "/home/colin"
        "/etc/NetworkManager/system-connections"
        "/etc/nixos"
        "/etc/ssh"
        # TODO: these individual files don't bind-mount. Xe shows the right way to handle files, i believe.
        # "/etc/machine-id"
        # # XXX these only need persistence because i have mutableUsers = true, i think
        # "/etc/group"
        # "/etc/passwd"
        # "/etc/shadow"
        # TODO: more granular persistence of /var/lib
        "/var/lib"
        "/var/log"
        "/mnt"
        # TODO: what even GOES in /srv?
        "/srv"
      ];
    };
  };
}

