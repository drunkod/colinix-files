# Terminal UI mail client
{ config, lib, sane-lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  sops.secrets."aerc_accounts" = {
    owner = config.users.users.colin.name;
    sopsFile = ../../secrets/universal/aerc_accounts.conf;
    format = "binary";
  };
  sane.fs."/home/colin/.config/aerc/accounts.conf" = sane-lib.fs.wantedSymlinkTo config.sops.secrets.aerc_accounts.path;
}
