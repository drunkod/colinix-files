# docs: <https://nixos.wiki/wiki/Distributed_build>
#
# this user exists for any machine on my network to receive build requests from some other machine.
# the build request happens from the origin computer's `root` user, so none of this is protected behind a login password.
# hence, the `nixremote` user's privileges should be as limited as possible.
{ config, ... }:
{
  users.users.nixremote = {
    isNormalUser = true;
    home = "/home/nixremote";
    group = "nixremote";
    subUidRanges = [
      { startUid=300000; count=1; }
    ];
    initialPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4KI7I2w5SvXRgUrXYiuBXPuTL+ZZsPoru5a2YkIuCf root@nixremote"
    ];
  };

  users.groups.nixremote = {};

  sane.users.nixremote = {
    fs."/".dir.acl = {
      # don't allow the user to write anywhere
      user = "root";
      group = "root";
    };
  };
}
