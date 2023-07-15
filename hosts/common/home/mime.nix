{ config, lib, ...}:

{
  # the xdg mime type for a file can be found with:
  # - `xdg-mime query filetype path/to/thing.ext`
  # we can have single associations or a list of associations.
  # there's also options to *remove* [non-default] associations from specific apps
  xdg.mime.enable = true;
  xdg.mime.defaultApplications = lib.mkMerge (
    builtins.map
      (p: lib.mkIf p.enabled p.mime)
      (builtins.attrValues config.sane.programs)
  );
}
