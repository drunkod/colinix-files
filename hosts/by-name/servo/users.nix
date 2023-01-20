{ config, ... }:

# installer docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
{
  # automatically log in at the virtual consoles.
  # using root here makes sure we always have an escape hatch
  services.getty.autologinUser = "root";

  # this is required to allow pleroma to send email.
  # raw `sendmail` works, but i think pleroma's passing it some funny flags or something, idk.
  # hack to fix that.
  users.users.pleroma.extraGroups = [ "postdrop" ];
}
