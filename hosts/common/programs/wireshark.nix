{ config, lib, ... }:
let
  cfg = config.sane.programs.wireshark;
in
{
  sane.programs.wireshark = {
    sandbox.method = "landlock";
    # sandbox.extraHomePaths = [
    #   ".wireshark/config"
    # ];
    sandbox.extraPaths = [
      "/proc/net"
    ];
    fs.".config/wireshark".dir = {};
    # sandbox.extraConfig = [
    #   # "--sane-sandbox-path" "/"
    #   # "--sane-sandbox-cap" "dac_override"
    #   # "--sane-sandbox-cap" "dac_read_search"
    #   "--sane-sandbox-cap" "net_admin"
    #   "--sane-sandbox-cap" "net_raw"
    #   # "--sane-sandbox-cap" "setpcap"
    # ];
    # sandbox.extraPaths = [ "/" ];
    # sandbox.method = "firejail";
    # sandbox.extraConfig = [
    #   # somehow needs `setpcap` (makes these bounding capabilities also be inherited?)
    #   # else no interfaces appear on the main page
    #   "--sane-sandbox-firejail-arg"
    #   "--ignore=caps.keep dac_override,dac_read_search,net_admin,net_raw"
    #   "--sane-sandbox-firejail-arg"
    #   "--caps.keep=dac_override,dac_read_search,net_admin,net_raw,setpcap"
    # ];
    slowToBuild = true;
  };

  # users.groups.wireshark = {};

  # security.wrappers = lib.mkIf cfg.enabled {
  #   wireshark = {
  #     source = "${cfg.package}/bin/wireshark";
  #     capabilities = "cap_dac_override,cap_dac_read_search,cap_net_raw,cap_net_admin,cap_setpcap+eip";  #< can probably be just `+p`
  #     owner = "root";
  #     group = "wireshark";
  #     permissions = "u+rx,g+x";
  #   };
  #   dumpcap = {
  #     source = "${cfg.package}/bin/.dumpcap-sandboxed";
  #     capabilities = "cap_net_raw,cap_net_admin+eip";  #< can probably be just `+p`
  #     owner = "root";
  #     group = "wireshark";
  #     permissions = "u+rx,g+x";
  #   };
  # };

  # programs.wireshark = lib.mkIf cfg.enabled {
  #   # adds a SUID* wrapper for wireshark's `dumpcap` program
  #   # *actually a setcap wrapper, which sets CAP_NET_ADMIN, CAP_NET_RAW
  #   # when executed by a member of the wireshark group.
  #   enable = true;
  #   package = cfg.package;
  # };
  # # the SUID wrapper can't also be a firejail (idk why? it might be that the binary's already *too* restricted).
  # security.wrappers = lib.mkIf cfg.enabled {
  #   dumpcap.source = lib.mkForce "${cfg.package}/bin/.dumpcap-sandboxed";
  # };
}
