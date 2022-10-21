# nb is a CLI-drive Personal Knowledge Manager
# - <https://xwmx.github.io/nb/>
#
# it's pretty opinionated:
# - autocommits (to git) excessively (disable-able)
# - inserts its own index files to give deterministic names to files
#
# it offers a primitive web-server
# and it offers some CLI query tools

{ lib, pkgs, ... }:
{
  sane.home-manager.extraPackages = [ pkgs.nb ];

  home-manager.users.colin = { config, ... }: {
    # nb markdown/personal knowledge manager
    home.file.".nb/knowledge".source = config.lib.file.mkOutOfStoreSymlink "/home/colin/dev/knowledge";
    home.file.".nb/.current".text = "knowledge";
    home.file.".nbrc".text = ''
      # manage with `nb settings`
      export NB_AUTO_SYNC=0
    '';
  };
}
