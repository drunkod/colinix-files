{ ... }:
{
  sane.programs.komikku = {
    sandbox.method = "bwrap";  # TODO:sandbox untested
    sandbox.wrapperType = "wrappedDerivation";
    secrets.".local/share/komikku/keyrings/plaintext.keyring" = ../../../secrets/common/komikku_accounts.json.bin;
    # downloads end up here, and without the toplevel database komikku doesn't know they exist.
    persist.byStore.plaintext = [ ".local/share/komikku" ];
  };
}
