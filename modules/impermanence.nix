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
        "/home/colin/archive"
        "/home/colin/dev"
        "/home/colin/ref"
        "/home/colin/tmp"
        "/home/colin/Music"
        "/home/colin/Pictures"
        "/home/colin/Videos"

        # cache is probably too big to fit on the tmpfs
        # TODO: we could bind-mount it to something which gets cleared per boot, though.
        "/home/colin/.cache"
        "/home/colin/.ssh"
        # intentionally omitted:
        # "/home/colin/.config"  # managed by home-manager
        # "/home/colin/.local"   # nothing useful in here
        # "/home/colin/.mozilla" # managed by home-manager

        "/etc/NetworkManager/system-connections"
        # "/etc/nixos"
        "/etc/ssh"
        # TODO: more granular persistence of /var/lib
        "/var/lib"
        "/var/log"
        "/mnt"
        # TODO: what even GOES in /srv?
        "/srv"
      ];
      files = [
        "/etc/machine-id"
        # "/home/colin/knowledge"
        "/home/colin/.zsh_history"
        # # XXX these only need persistence because i have mutableUsers = true, i think
        # "/etc/group"
        # "/etc/passwd"
        # "/etc/shadow"
        # { file = "/home/test2"; persistentStoragePath = "/nix/persist"; }
      ];
    };
  };
}

