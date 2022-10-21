# Terminal UI mail client
{ config, ... }:
{
  sops.secrets."aerc_accounts" = {
    owner = config.users.users.colin.name;
    sopsFile = ../../../../secrets/universal/aerc_accounts.conf;
    format = "binary";
  };
  home-manager.users.colin = let sysconfig = config; in { config, ... }: {
    # aerc TUI mail client
    xdg.configFile."aerc/accounts.conf".source =
      config.lib.file.mkOutOfStoreSymlink sysconfig.sops.secrets.aerc_accounts.path;
  };
}
