{ ... }:
{
  sane.services.kiwix-serve = {
    enable = true;
    port = 8013;
    zimPaths = [ "/var/lib/uninsane/www-archive/wikipedia_en_all_maxi_2022-05.zim" ];
  };
}
