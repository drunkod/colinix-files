# Terminal UI mail client
{ ... }:

{
  sane.programs.aerc = {
    secrets.".config/aerc/accounts.conf" = ../../../secrets/common/aerc_accounts.conf.bin;
    mime."x-scheme-handler/mailto" = "aerc.desktop";
  };
}
