{ pkgs, ... }:
{
  sane.programs.tuba = {
    package = pkgs.symlinkJoin {
      # ship a `tuba` alias to the actual tuba binary, since i can never remember its name
      name = "tuba";
      paths = [
        pkgs.tuba
        (pkgs.runCommandLocal "tuba" {} ''
          mkdir -p $out/bin
          ln -s ${pkgs.tuba}/bin/dev.geopjr.Tuba $out/bin/tuba
        '')
      ];
    };
    suggestedPrograms = [ "gnome-keyring" ];
  };
}
