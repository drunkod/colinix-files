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
  fmtIncludes = paths: concatStringsSep
    "\n"
    (map (path: "$INCLUDE ${path}") paths);
  configFile = toml.generate "trust-dns.toml" {
    listen_addrs_ipv4 = cfg.listenAddrsIPv4;
    zones = attrValues (
      mapAttrs (zone: zcfg: {
        inherit zone;
        zone_type = "Primary";
        file = pkgs.writeText "${zone}.zone" ''
          $TTL ${toString zcfg.TTL}
          ${fmtRecordAttrs "IN" "SOA" zcfg.inet.SOA}
          ${fmtRecordAttrs "IN" "A" zcfg.inet.A}
          ${fmtRecordAttrs "IN" "CNAME" zcfg.inet.CNAME}
          ${fmtRecordAttrs "IN" "MX" zcfg.inet.MX}
          ${fmtRecordAttrs "IN" "NS" zcfg.inet.NS}
          ${fmtRecordAttrs "IN" "SRV" zcfg.inet.SRV}
          ${fmtRecordAttrs "IN" "TXT" zcfg.inet.TXT}
          ${fmtIncludes zcfg.include}
          ${zcfg.extraConfig}
        '';
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
              description = "default TTL";
              default = 3600;
            };
            include = mkOption {
              type = types.listOf types.str;
              description = "paths of other zone files to $INCLUDE into this one";
              default = [];
            };
            extraConfig = mkOption {
              type = types.lines;
              description = "extra lines to append to the zone file";
              default = "";
            };
            inet = {
              SOA = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "Start of Authority record(s)";
                default = {};
              };
              A = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "IPv4 address record(s)";
                default = {};
              };
              CNAME = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "canonical name record(s)";
                default = {};
              };
              MX = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "mail exchanger record(s)";
                default = {};
              };
              NS = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "name server record(s)";
                default = {};
              };
              SRV = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "service record(s)";
                default = {};
              };
              TXT = mkOption {
                type = types.attrsOf (types.listOf types.str);
                description = "text record(s)";
                default = {};
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
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
    };
  };
}
