# docs:
# - <https://docs.ejabberd.im/admin/configuration/basic>
{ lib, ... }:

# XXX disabled: fails to start because of `mnesia_tm` dependency
# lib.mkIf false
{
  sane.impermanence.service-dirs = [
    { user = "ejabberd"; group = "ejabberd"; directory = "/var/lib/ejabberd"; }
  ];
  networking.firewall.allowedTCPPorts = [
    5222  # XMPP client -> server
    5269  # XMPP server -> server
  ];

  # provide access to certs
  users.users.ejabberd.extraGroups = [ "nginx" ];

  # TODO: allocate UIDs/GIDs ?
  services.ejabberd.enable = true;
  services.ejabberd.configFile = builtins.toFile "ejabberd.yaml" ''
    hosts:
      - uninsane.org

    # none | emergency | alert | critical | error | warning | notice | info | debug
    loglevel: debug

    acme:
      auto: false
    certfiles:
      - /var/lib/acme/uninsane.org/fullchain.pem
      - /var/lib/acme/uninsane.org/key.pem

    pam_userinfotype: jid

    # see: <https://docs.ejabberd.im/admin/configuration/listen/>
    # TODO: host web admin panel
    listen:
      -
        port: 5222
        module: ejabberd_c2s
        starttls: true
      -
        port: 5269
        module: ejabberd_s2s_in
        starttls: true
  '';
}
