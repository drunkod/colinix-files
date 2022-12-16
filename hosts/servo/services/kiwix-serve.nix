{ ... }:
{
  sane.services.kiwix-serve = {
    enable = true;
    port = 8013;
    zimPaths = [ "/var/lib/uninsane/www-archive/wikipedia_en_simple_all_mini_2022-11.zim" ];
  };
}
