# mail archiving/synchronization tool.
#
# manually download all emails for an account with
# - `offlineimap -a <accountname>`
#
# view account names inside the secrets file, listed below.
{ config, sane-lib, ... }:

{
  sops.secrets."offlineimaprc" = {
    owner = config.users.users.colin.name;
    sopsFile = ../../../secrets/universal/offlineimaprc.bin;
    format = "binary";
  };
  sane.programs.offlineimap.fs.".config/offlineimap/config" = sane-lib.fs.wantedSymlinkTo config.sops.secrets.offlineimaprc.path;
}

