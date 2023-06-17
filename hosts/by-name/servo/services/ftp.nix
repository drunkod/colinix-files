# docs:
# - <https://github.com/drakkan/sftpgo>
# - config options: <https://github.com/drakkan/sftpgo/blob/main/docs/full-configuration.md>
# - config defaults: <https://github.com/drakkan/sftpgo/blob/main/sftpgo.json>
#
# sftpgo is a FTP server that also supports WebDAV, SFTP, and web clients.

{ ... }:
{
  sane.ports.ports."21" = {
    protocol = [ "tcp" ];
    visibleTo.lan = true;
    description = "colin-FTP server";
  };

  services.sftpgo = {
    enable = false;
    # enable = true;
    settings.ftpd.bindings = [{
      address = "10.0.10.5";
      port = 21;

      banner = ''
        Welcome, friends, to Colin's read-only FTP server! Also available via NFS on the same host.
        Please let me know if anything's broken or not as it should be. Otherwise, browse and DL freely :)
      '';
      hash_support = true;

      debug = true;
    }];
  };
}
