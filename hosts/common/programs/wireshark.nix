{ config, lib, ... }:
let
  cfg = config.sane.programs.wireshark;
in
{
  sane.programs.wireshark = {
    sandbox.method = "firejail";
    sandbox.extraFirejailConfig = ''
      # somehow needs `setpcap` (makes these bounding capabilities also be inherited?)
      # else no interfaces appear on the main page
      ignore caps.keep dac_override,dac_read_search,net_admin,net_raw
      caps.keep dac_override,dac_read_search,net_admin,net_raw,setpcap
    '';
    slowToBuild = true;
  };

  programs.wireshark = lib.mkIf cfg.enabled {
    # adds a SUID wrapper for wireshark's `dumpcap` program
    enable = true;
    package = cfg.package;
  };
  # the SUID wrapper can't also be a firejail (idk why? it might be that the binary's already *too* restricted).
  security.wrappers.dumpcap.source = lib.mkIf cfg.enabled (lib.mkForce "${cfg.package}/bin/.dumpcap-firejailed");
}
