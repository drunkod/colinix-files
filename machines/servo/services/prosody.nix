# create users with:
# - `sudo -u prosody prosodyctl adduser colin@uninsane.org`

{ ... }:
{
  sane.impermanence.service-dirs = [
    { user = "prosody"; group = "prosody"; directory = "/var/lib/prosody"; }
  ];
  networking.firewall.allowedTCPPorts = [
    5222  # XMPP client -> server
    5269  # XMPP server -> server
    5280  # Prosody HTTP port  (necessary?)
    5281  # Prosody HTTPS port  (necessary?)
  ];

  # provide access to certs
  users.users.prosody.extraGroups = [ "nginx" ];

  security.acme.certs."uninsane.org".extraDomainNames = [
    "conference.xmpp.uninsane.org"
    "upload.xmpp.uninsane.org"
  ];

  services.prosody = {
    enable = true;
    admins = [ "colin@uninsane.org" ];
    # allowRegistration = false;
    # extraConfig = ''
    #   s2s_require_encryption = true
    #   c2s_require_encryption = true
    # '';

    # extraModules = [ "private" "vcard" "privacy" "compression" "component" "muc" "pep" "adhoc" "lastactivity" "admin_adhoc" "blocklist"];

    ssl.cert = "/var/lib/acme/uninsane.org/fullchain.pem";
    ssl.key = "/var/lib/acme/uninsane.org/key.pem";

    muc = [
      {
        domain = "conference.xmpp.uninsane.org";
      }
    ];
    uploadHttp.domain = "upload.xmpp.uninsane.org";

    virtualHosts = {
      localhost = {
        domain = "localhost";
        enabled = true;
      };
      "uninsane.org" = {
        domain = "uninsane.org";
        enabled = true;
        ssl.cert = "/var/lib/acme/uninsane.org/fullchain.pem";
        ssl.key = "/var/lib/acme/uninsane.org/key.pem";
      }; 
    };
  };
}
