{ pkgs, secrets, ... }:

{
  systemd.services.ddns-he = {
    description = "update dynamic DNS entries for HurricaneElectric";
    # HE DDNS API is documented: https://dns.he.net/docs.html
    script = let
      pass = secrets.ddns-he.password;
      crl = "${pkgs.curl}/bin/curl -4";
    in ''
      ${crl} "https://he.uninsane.org:${pass}@dyn.dns.he.net/nic/update?hostname=he.uninsane.org"
      ${crl} "https://native.uninsane.org:${pass}@dyn.dns.he.net/nic/update?hostname=native.uninsane.org"
      ${crl} "https://uninsane.org:${pass}@dyn.dns.he.net/nic/update?hostname=uninsane.org"
    '';
  };
  systemd.timers.ddns-he.timerConfig = {
    OnStartupSec = "2min";
    OnUnitActiveSec = "10min";
  };
}
