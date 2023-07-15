{ pkgs, ... }:
{
  sane.programs.gthumb = {
    # compile without webservices to avoid the expensive webkitgtk dependency
    package = pkgs.gthumb.override { withWebservices = false; };
    mime."image/heif" = "org.gnome.gThumb.desktop";  # apple codec
    mime."image/png" = "org.gnome.gThumb.desktop";
    mime."image/jpeg" = "org.gnome.gThumb.desktop";
  };
}
