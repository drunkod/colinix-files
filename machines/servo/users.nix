{ config, ... }:

# installer docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
{
  # automatically log in at the virtual consoles.
  # using root here makes sure we always have an escape hatch
  services.getty.autologinUser = "root";

  # gitea doesn't create the git user
  users.users.git = {
    description = "Gitea Service";
    home = "/var/lib/gitea";
    useDefaultShell = true;
    group = "gitea";
    uid = config.sane.allocations.git-uid;
    isSystemUser = true;
    # sendmail access (not 100% sure if this is necessary)
    extraGroups = [ "postdrop" ];
  };

  # this is required to allow pleroma to send email.
  # raw `sendmail` works, but i think pleroma's passing it some funny flags or something, idk.
  # hack to fix that.
  users.users.pleroma.extraGroups = [ "postdrop" ];
  users.users.dhcpcd.uid = config.sane.allocations.dhcpcd-uid;
  users.groups.dhcpcd.gid = config.sane.allocations.dhcpcd-gid;
}
