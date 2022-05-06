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
    smtpd_milters = inet:localhost:8891
    non_smtpd_milters = $smtpd_milters
    milter_default_action = accept
  '';

  services.opendkim.enable = true;
  services.opendkim.domains = "csl:uninsane.org";

  # we use a custom (inet) socket, because the default perms
  # of the unix socket don't allow postfix to connect
  services.opendkim.socket = "inet:8891@localhost";
  # selectors can be used to disambiguate sender machines.
  # keeping this the same as the hostname seems simplest
  services.opendkim.selector = "mx";

  systemd.services.postfix.after = ["wg0veth.service"];
  systemd.services.postfix.serviceConfig = {
    # run this behind the OVPN static VPN
    NetworkNamespacePath = "/run/netns/ovpns";
  };
}
