{ sxmoPath, sxmoEnvSetup, pkgs }:
{
  description = "programmable input dispatcher";
  path = sxmoPath;
  script = ''
    ${sxmoEnvSetup}
    ${pkgs.coreutils}/bin/rm -f $XDG_RUNTIME_DIR/bonsai
    exec ${pkgs.bonsai}/bin/bonsaid -t $XDG_CONFIG_HOME/sxmo/bonsai_tree.json
  '';
  serviceConfig.Type = "simple";
  serviceConfig.Restart = "always";
  serviceConfig.RestartSec = "5s";
}
