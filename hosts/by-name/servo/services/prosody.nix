# example configs:
# - official: <https://prosody.im/doc/example_config>
# - nixos: <https://github.com/kittywitch/nixfiles/blob/main/services/prosody.nix>
# config options:
# - <https://prosody.im/doc/configure>
#
# modules:
# - main: <https://prosody.im/doc/modules>
# - community: <https://modules.prosody.im/index.html>
#
# create users with:
# - `sudo -u prosody prosodyctl adduser colin@uninsane.org`
# sanity checks:
# - `sudo -u prosody -g prosody prosodyctl check connectivity`
# - `sudo -u prosody -g prosody prosodyctl check turn`
# - `sudo -u prosody -g prosody prosodyctl check`  (dns, config, certs)
#
# federation/support matrix:
# - nixnet.services (runs ejabberd):
#   - WORKS: sending and receiving PMs and calls (2023/10/15)
#     - N.B.: it didn't originally work; was solved by disabling the lua-unbound DNS option & forcing the system/local resolver
# - cheogram (XMPP <-> SMS gateway):
#   - WORKS: sending and receiving PMs, images (2023/10/15)
#   - PARTIAL: calls (xmpp -> tel works; tel -> xmpp fails)
#     - maybe i need to setup stun/turn
#
# TODO:
# - fix cheogram -> uninsane.org calls
#   - enable mod_turn_external?
# - ensure muc is working
# - enable file uploads
#   - "upload.xmpp.uninsane.org:http_upload: URL: <https://upload.xmpp.uninsane.org:5281/upload> - Ensure this can be reached by users"
# - move proxy65 to own port
#   - "portmanager: Failed to open server port 5000 on *, this port is in use by another application"
#   - port 5000 is in use by nix-serve (`sudo lsof -P -i4`)
# - disable or fix bosh (jabber over http):
#   - "certmanager: No certificate/key found for client_https port 0"

{ lib, pkgs, ... }:

{
  sane.persist.sys.plaintext = [
    { user = "prosody"; group = "prosody"; path = "/var/lib/prosody"; }
  ];
  sane.ports.ports."5222" = {
    protocol = [ "tcp" ];
    visibleTo.lan = true;
    visibleTo.wan = true;
    description = "colin-xmpp-client-to-server";
  };
  sane.ports.ports."5223" = {
    protocol = [ "tcp" ];
    visibleTo.lan = true;
    visibleTo.wan = true;
    description = "colin-xmpps-client-to-server";  # XMPP over TLS
  };
  sane.ports.ports."5269" = {
    protocol = [ "tcp" ];
    visibleTo.wan = true;
    description = "colin-xmpp-server-to-server";
  };
  sane.ports.ports."5270" = {
    protocol = [ "tcp" ];
    visibleTo.wan = true;
    description = "colin-xmpps-server-to-server";  # XMPP over TLS
  };
  sane.ports.ports."5280" = {
    protocol = [ "tcp" ];
    visibleTo.lan = true;
    visibleTo.wan = true;
    description = "colin-xmpp-bosh";
  };
  sane.ports.ports."5281" = {
    protocol = [ "tcp" ];
    visibleTo.lan = true;
    visibleTo.wan = true;
    description = "colin-xmpp-prosody-https";  # necessary?
  };

  # provide access to certs
  users.users.prosody.extraGroups = [ "nginx" ];

  security.acme.certs."uninsane.org".extraDomainNames = [
    "xmpp.uninsane.org"
    "conference.xmpp.uninsane.org"
    "upload.xmpp.uninsane.org"
  ];

  # exists so the XMPP server's cert can obtain altNames for all its resources
  services.nginx.virtualHosts."xmpp.uninsane.org" = {
    useACMEHost = "uninsane.org";
  };
  services.nginx.virtualHosts."conference.xmpp.uninsane.org" = {
    useACMEHost = "uninsane.org";
  };
  services.nginx.virtualHosts."upload.xmpp.uninsane.org" = {
    useACMEHost = "uninsane.org";
  };

  sane.dns.zones."uninsane.org".inet = {
    # XXX: SRV records have to point to something with a A/AAAA record; no CNAMEs
    A."xmpp" =                "%ANATIVE%";
    CNAME."conference.xmpp" = "xmpp";
    CNAME."upload.xmpp" =     "xmpp";

    # _Service._Proto.Name    TTL Class SRV    Priority Weight Port Target
    # - <https://xmpp.org/extensions/xep-0368.html>
    # something's requesting the SRV records for conference.xmpp, so let's include it
    # nothing seems to request XMPP SRVs for the other records (except @)
    # lower numerical priority field tells clients to prefer this method
    SRV."_xmpps-client._tcp.conference.xmpp" =       "3 50 5223 xmpp";
    SRV."_xmpps-server._tcp.conference.xmpp" =       "3 50 5270 xmpp";
    SRV."_xmpp-client._tcp.conference.xmpp" =        "5 50 5222 xmpp";
    SRV."_xmpp-server._tcp.conference.xmpp" =        "5 50 5269 xmpp";

    SRV."_xmpps-client._tcp" =                "3 50 5223 xmpp";
    SRV."_xmpps-server._tcp" =                "3 50 5270 xmpp";
    SRV."_xmpp-client._tcp" =                 "5 50 5222 xmpp";
    SRV."_xmpp-server._tcp" =                 "5 50 5269 xmpp";
  };

  # help Prosody find its certificates.
  # pointing it to /var/lib/acme doesn't quite work because it expects the private key
  # to be named `privkey.pem` instead of acme's `key.pem`
  # <https://prosody.im/doc/certificates#automatic_location>
  sane.fs."/etc/prosody/certs/uninsane.org/fullchain.pem".symlink.target =
    "/var/lib/acme/uninsane.org/fullchain.pem";
  sane.fs."/etc/prosody/certs/uninsane.org/privkey.pem".symlink.target =
    "/var/lib/acme/uninsane.org/key.pem";

  services.prosody = {
    enable = true;
    package = pkgs.prosody.override {
      # XXX(2023/10/15): build without lua-unbound support.
      # this forces Prosody to fall back to the default Lua DNS resolver, which seems more reliable.
      # fixes errors like "unbound.queryXYZUV: Resolver error: out of memory"
      # related: <https://issues.prosody.im/1737#comment-11>
      lua.withPackages = selector: pkgs.lua.withPackages (p:
        selector (p // { luaunbound = null; })
      );
    };
    admins = [ "colin@uninsane.org" ];
    # allowRegistration = false;
    # extraConfig = ''
    #   s2s_require_encryption = true
    #   c2s_require_encryption = true
    # '';

    ssl.cert = "/var/lib/acme/uninsane.org/fullchain.pem";
    ssl.key = "/var/lib/acme/uninsane.org/key.pem";

    muc = [
      {
        domain = "conference.xmpp.uninsane.org";
      }
    ];
    uploadHttp.domain = "upload.xmpp.uninsane.org";

    virtualHosts = {
      # "Prosody requires at least one enabled VirtualHost to function. You can
      # safely remove or disable 'localhost' once you have added another."
      # localhost = {
      #   domain = "localhost";
      #   enabled = true;
      # };
      "xmpp.uninsane.org" = {
        domain = "uninsane.org";
        enabled = true;
        ssl.cert = "/var/lib/acme/uninsane.org/fullchain.pem";
        ssl.key = "/var/lib/acme/uninsane.org/key.pem";
      };
    };

    ## modules:
    # these are enabled by default, via <repo:nixos/nixpkgs:/pkgs/servers/xmpp/prosody/default.nix>
    # - cloud_notify
    # - http_upload
    # - vcard_muc
    # these are enabled by the module defaults (services.prosody.modules.<foo>)
    # - admin_adhoc
    # - blocklist
    # - bookmarks
    # - carbons
    # - cloud_notify
    # - csi
    # - dialback
    # - disco
    # - http_files
    # - mam
    # - pep
    # - ping
    # - private
    #   - XEP-0049: let clients store arbitrary (private) data on the server
    # - proxy65
    # - register
    # - roster
    # - saslauth
    # - smacks
    # - time
    # - tls
    # - uptime
    # - vcard_legacy
    # - version
    extraModules = [
      "adhoc"  # TODO: disable (should be auto-loaded by admin_adhoc)
      # "admin_adhoc"
      # "blocklist"
      # "component"  # not supposed to be manually enabled
      # "compression"  # moved to community modules; questionable safety
      "lastactivity"  # XEP-0012: allow users to query how long another user has been idle for
      # "muc"  # TODO: muc should be enabled as a component
      # "pep"
      # "privacy"  # replaced by mod_blocklist
      # "private"
      # "vcard"  # replaced by vcard_legacy
    ];

    extraConfig = ''
      -- see: <https://prosody.im/doc/certificates#automatic_location>
      -- try to solve: "certmanager: Error indexing certificate directory /etc/prosody/certs: cannot open /etc/prosody/certs: No such file or directory"
      -- only, this doesn't work because prosody doesn't like acme's naming scheme
      -- certificates = "/var/lib/acme"

      c2s_direct_tls_ports = { 5223 }
      s2s_direct_tls_ports = { 5270 }
    '';
  };
}
