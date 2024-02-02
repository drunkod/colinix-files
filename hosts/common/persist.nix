{ ... }:

{
  sane.persist.stores.private.origin = "/home/alex/private";
  # store /home/alex/a/b in /home/private/a/b instead of /home/private/home/alex/a/b
  sane.persist.stores.private.prefix = "/home/alex";

  sane.persist.sys.byStore.plaintext = [
    # TODO: these should be private.. somehow
    "/var/log"
    "/var/backup"  # for e.g. postgres dumps
  ];
  sane.persist.sys.byStore.cryptClearOnBoot = [
    "/var/lib/systemd/coredump"
  ];
}
