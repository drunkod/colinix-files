{ config, lib, ... }:

let
  submissionOptions = {
    smtpd_tls_security_level = "encrypt";
    smtpd_sasl_auth_enable = "yes";
    smtpd_sasl_type = "dovecot";
    smtpd_sasl_path = "/run/dovecot2/auth";
    smtpd_sasl_security_options = "noanonymous";
    smtpd_sasl_local_domain = "uninsane.org";
    smtpd_client_restrictions = "permit_sasl_authenticated,reject";
    # reuse the virtual map so that sender mapping matches recipient mapping
    smtpd_sender_login_maps = "hash:/var/lib/postfix/conf/virtual";
    smtpd_sender_restrictions = "reject_sender_login_mismatch";
    smtpd_recipient_restrictions = "reject_non_fqdn_recipient,permit_sasl_authenticated,reject";
  };
in
{
  sane.persist.sys.plaintext = [
    # TODO: mode? could be more granular
    { user = "opendkim"; group = "opendkim"; directory = "/var/lib/opendkim"; }
    { user = "root"; group = "root"; directory = "/var/lib/postfix"; }
    { user = "root"; group = "root"; directory = "/var/spool/mail"; }
    # *probably* don't need these dirs:
    # "/var/lib/dhparams"          # https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/dhparams.nix
    # "/var/lib/dovecot"
  ];

  networking.firewall.allowedTCPPorts = [
    25   # SMTP
    143  # IMAP
    465  # SMTPS
    587  # SMTPS/submission
    993  # IMAPS
  ];

  # exists only to manage certs for dovecot
  services.nginx.virtualHosts."imap.uninsane.org" = {
    enableACME = true;
  };
  # exists only to manage certs for Postfix
  services.nginx.virtualHosts."mx.uninsane.org" = {
    enableACME = true;
  };


  sane.services.trust-dns.zones."uninsane.org".inet = {
    MX."@" = "10 mx.uninsane.org.";
    # XXX: RFC's specify that the MX record CANNOT BE A CNAME
    A."mx" = "185.157.162.178";
    CNAME."imap" = "native";

    # Sender Policy Framework:
    #   +mx     => mail passes if it originated from the MX
    #   +a      => mail passes if it originated from the A address of this domain
    #   +ip4:.. => mail passes if it originated from this IP
    #   -all    => mail fails if none of these conditions were met
    TXT."@" = "v=spf1 a mx -all";

    # DKIM public key:
    TXT."mx._domainkey" =
      "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCkSyMufc2KrRx3j17e/LyB+3eYSBRuEFT8PUka8EDX04QzCwDPdkwgnj3GNDvnB5Ktb05Cf2SJ/S1OLqNsINxJRWtkVfZd/C339KNh9wrukMKRKNELL9HLUw0bczOI4gKKFqyrRE9qm+4csCMAR79Te9FCjGV/jVnrkLdPT0GtFwIDAQAB"
    ;

    # DMARC fields <https://datatracker.ietf.org/doc/html/rfc7489>:
    #   p=none|quarantine|reject: what to do with failures
    #   sp = p but for subdomains
    #   rua = where to send aggregrate reports
    #   ruf = where to send individual failure reports
    #   fo=0|1|d|s  controls WHEN to send failure reports
    #     (1=on bad alignment; d=on DKIM failure; s=on SPF failure);
    # Additionally:
    #   adkim=r|s  (is DKIM relaxed [default] or strict)
    #   aspf=r|s   (is SPF relaxed [default] or strict)
    #   pct = sampling ratio for punishing failures (default 100 for 100%)
    #   rf = report format
    #   ri = report interval
    TXT."_dmarc" =
      "v=DMARC1;p=quarantine;sp=reject;rua=mailto:admin+mail@uninsane.org;ruf=mailto:admin+mail@uninsane.org;fo=1:d:s"
    ;
  };

  services.postfix.enable = true;
  services.postfix.hostname = "mx.uninsane.org";
  services.postfix.origin = "uninsane.org";
  services.postfix.destination = [ "localhost" "uninsane.org" ];
  services.postfix.sslCert = "/var/lib/acme/mx.uninsane.org/fullchain.pem";
  services.postfix.sslKey = "/var/lib/acme/mx.uninsane.org/key.pem";

  services.postfix.virtual = ''
    notify.matrix@uninsane.org matrix-synapse
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
    smtp_tls_security_level = may
  '';

  services.postfix.enableSubmission = true;
  services.postfix.submissionOptions = submissionOptions;
  services.postfix.enableSubmissions = true;
  services.postfix.submissionsOptions = submissionOptions;

  systemd.services.postfix.after = [ "wireguard-wg-ovpns.service" ];
  systemd.services.postfix.partOf = [ "wireguard-wg-ovpns.service" ];
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

  systemd.services.opendkim.after = [ "wireguard-wg-ovpns.service" ];
  systemd.services.opendkim.partOf = [ "wireguard-wg-ovpns.service" ];
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
  services.dovecot2.extraConfig =
  let
    passwdFile = config.sops.secrets.dovecot_passwd.path;
  in
    ''
    passdb {
      driver = passwd-file
      args = ${passwdFile}
    }
    userdb {
      driver = passwd-file
      args = ${passwdFile}
    }

    # allow postfix to query our auth db
    service auth {
      unix_listener auth {
        mode = 0660
        user = postfix
        group = postfix
      }
    }
    auth_mechanisms = plain login


    mail_debug = yes
    auth_debug = yes
    # verbose_ssl = yes
  '';

  #### OUTGOING MESSAGE REWRITING:
  services.postfix.enableHeaderChecks = true;
  services.postfix.headerChecks = [
    # intercept gitea registration confirmations and manually screen them
    {
      # headerChecks are somehow ignorant of alias rules: have to redirect to a real user
      action = "REDIRECT colin@uninsane.org";
      pattern = "/^Subject: Please activate your account/";
    }
    # intercept Matrix registration confirmations
    {
      action = "REDIRECT colin@uninsane.org";
      pattern = "/^Subject:.*Validate your email/";
    }
    # XXX postfix only supports performing ONE action per header.
    # {
    #   action = "REPLACE Subject: git application: Please activate your account";
    #   pattern = "/^Subject:.*activate your account/";
    # }
  ];

  sops.secrets.dovecot_passwd = {
    sopsFile = ../../../secrets/servo.yaml;
    owner = config.users.users.dovecot2.name;
    # TODO: debug why mail can't be sent without this being world-readable
    mode = "0444";
  };
}
