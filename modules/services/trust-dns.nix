{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.sane.services.trust-dns;
  toml = pkgs.formats.toml { };
  fmtRecord = proto: rrtype: name: value: "${name}\t${proto}\t${rrtype}\t${value}";
  fmtRecordList = proto: rrtype: name: values: concatStringsSep
    "\n"
    (map (fmtRecord proto rrtype name) values)
  ;
  fmtRecordAttrs = proto: rrtype: rrAttrs:
    concatStringsSep
      "\n"
      (
        attrValues (
          mapAttrs
            (name: fmtRecordList proto rrtype name)
            rrAttrs
        )
      );
  configFile = toml.generate "trust-dns.toml" {
    listen_addrs_ipv4 = cfg.listenAddrsIPv4;
    zones = attrValues (
      mapAttrs (zone: zcfg: {
        inherit zone;
        zone_type = "Primary";
        file = pkgs.writeText "${zone}.zone" (''
          $TTL ${toString zcfg.TTL}
          ${fmtRecordAttrs "IN" "SOA" zcfg.inet.SOA}
        '' + zcfg.extraConfig);
      }) cfg.zones
    );
  };
in
{
  options = {
    sane.services.trust-dns = {
      enable = mkOption {
        default = false;
        type = types.bool;
      };
      listenAddrsIPv4 = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "array of ipv4 addresses on which to listen for DNS queries";
      };
      # reference <nixpkgs:nixos/modules/services/web-servers/nginx/vhost-options.nix>
      zones = mkOption {
        type = types.attrsOf (types.submodule {
          options = {
            TTL = mkOption {
              type = types.int;
              default = 3600;
              description = "default TTL";
            };
            extraConfig = mkOption {
              type = types.lines;
              default = "";
              description = "extra lines to append to the zone file";
            };
            inet = {
              SOA = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "Start of Authority record";
              };
            };
          };
        });
        default = {};
        description = "Declarative zone config";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 53 ];
    networking.firewall.allowedUDPPorts = [ 53 ];

    systemd.services.trust-dns = {
      description = "trust-dns DNS server";
      serviceConfig = {
        ExecStart = ''
          ${pkgs.trust-dns}/bin/named \
            --config ${configFile} \
            --zonedir /
        '';
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "10s";
        # TODO: hardening (like, don't run as root!)
      };
      wants = [ "ddns-trust-dns.service" "ddns-trust-dns.timer" ];
      # XXX: can't be after ddns-trust-dns.service, because the latter `restarts` this one -- *before* it's done activating.
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
