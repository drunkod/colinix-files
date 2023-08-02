{ pkgs, ... }:
{
  sane.programs.chatty = {
    package = pkgs.chatty.override {
      # the OAuth feature (presumably used for web-based logins) pulls a full webkitgtk.
      # especially when using the gtk3 version of evolution-data-server, it's an ancient webkitgtk_4_1.
      # disable OAuth for a faster build & smaller closure
      evolution-data-server = pkgs.evolution-data-server.override {
        enableOAuth2 = false;
        gnome-online-accounts = pkgs.gnome-online-accounts.override {
          # disables the upstream "goabackend" feature -- presumably "Google Online Account"?
          # frees us from webkit_4_1, in turn.
          enableBackend = false;
        };
      };
    };
  };
}
