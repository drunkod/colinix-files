{ ... }:

{
  sane.persist.stores.private.origin = "/home/colin/private";
  # store /home/colin/a/b in /home/private/a/b instead of /home/private/home/colin/a/b
  sane.persist.stores.private.prefix = "/home/colin";
}
