{ config, lib, pkgs, ... }:
let
  cfg = config.sane.gui.sxmo.bonsaid;
in
{
  options = with lib; {
    sane.gui.sxmo.bonsaid.package = mkOption {
      type = types.package;
      default = pkgs.bonsai;
    };
  };
  config = {
    sane.user.services.bonsaid = {
      description = "programmable input dispatcher";
      script = ''
        ${pkgs.coreutils}/bin/rm -f $XDG_RUNTIME_DIR/bonsai
        exec ${cfg.package}/bin/bonsaid -t $XDG_CONFIG_HOME/sxmo/bonsai_tree.json
      '';
      serviceConfig.Type = "simple";
      serviceConfig.Restart = "always";
      serviceConfig.RestartSec = "5s";
    };
  };
}
