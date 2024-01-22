{ ... }:
{
  sane.programs.evince = {
    sandbox.method = "firejail";
    mime.associations."application/pdf" = "org.gnome.Evince.desktop";
  };
}
