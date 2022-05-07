{ config, pkgs, lib, ... }:

{
  services.postfix.enable = true;
  services.postfix.hostname = "mx.uninsane.org";
  services.postfix.origin = "uninsane.org";
  services.postfix.destination = ["localhost" "uninsane.org"];

  services.postfix.virtual = ''
    @uninsane.org colin
  '';

  services.postfix.extraConfig = ''
    # smtpd_milters = local:/run/opendkim/opendkim.sock
    # milter docs: http://www.postfix.org/MILTER_README.html
    # mail filters for receiving email and authorized SMTP clients
    # smtpd_milters = inet:185.157.162.190:8891
    smtpd_milters = unix:/run/opendkim/opendkim.sock
    # mail filters for sendmail
    non_smtpd_milters = $smtpd_milters
    milter_default_action = accept
    inet_protocols = ipv4
  '';

  systemd.services.postfix.after = ["wg0veth.service"];
  systemd.services.postfix.serviceConfig = {
    # run this behind the OVPN static VPN
    NetworkNamespacePath = "/run/netns/ovpns";
  };


  services.opendkim.enable = true;
  # services.opendkim.domains = "csl:uninsane.org";
  services.opendkim.domains = "uninsane.org";

  # we use a custom (inet) socket, because the default perms
  # of the unix socket don't allow postfix to connect.
  # this sits on the machine-local 10.0.1 interface because it's the closest
  # thing to a loopback interface shared by postfix and opendkim netns.
  # services.opendkim.socket = "inet:8891@185.157.162.190";
  # services.opendkim.socket = "local:/run/opendkim.sock";
  # selectors can be used to disambiguate sender machines.
  # keeping this the same as the hostname seems simplest
  services.opendkim.selector = "mx";

  systemd.services.opendkim.after = ["wg0veth.service"];
  systemd.services.opendkim.serviceConfig = {
    # run this behind the OVPN static VPN
    NetworkNamespacePath = "/run/netns/ovpns";
    # /run/opendkim/opendkim.sock needs to be rw by postfix
    UMask = lib.mkForce "0011";
  };

  # inspired by https://gitlab.com/simple-nixos-mailserver/nixos-mailserver/
  services.dovecot2.enable = true;
  services.dovecot2.sslServerCert = "/var/lib/acme/imap.uninsane.org/fullchain.pem";
  services.dovecot2.sslServerKey = "/var/lib/acme/imap.uninsane.org/key.pem";
  services.dovecot2.enablePAM = false;
  # passwd file looks like /etc/passwd.
  # use nix run nixpkgs.apacheHttpd -c htpasswd -nbB "" "my passwd" to generate the password
  services.dovecot2.extraConfig = ''
    passdb {
      driver = passwd-file
      args = /etc/nixos/secrets/dovecot.passwd
    }
    userdb {
      driver = passwd-file
      args = /etc/nixos/secrets/dovecot.passwd
    }

    mail_debug = yes
    auth_debug = yes
    # verbose_ssl = yes
  '';
}
