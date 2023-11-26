# as of 2023/11/26: complete downloaded blockchain should be 200GiB on disk, give or take.
{ ... }:
{
  sane.persist.sys.byStore.ext = [
    # /var/lib/monero/lmdb is what consumes most of the space
    { user = "monero"; group = "monero"; path = "/var/lib/monero"; }
  ];

  services.monero.enable = true;
  services.monero.limits.upload = 5000;  # in kB/s
}
