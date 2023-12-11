{ config, lib, pkgs, ... }:
let
  # [ ProgramConfig ]
  enabledPrograms = builtins.filter
    (p: p.enabled)
    (builtins.attrValues config.sane.programs);

  fmtAssoc = regex: cmd: ''
    ${cmd}
      ${regex}
  '';
  assocs = builtins.map
    (program: lib.mapAttrsToList fmtAssoc program.mime.urlAssociations)
    enabledPrograms;
  assocs' = lib.flatten assocs;
in
{
  sane.programs.mimeo = {
    package = pkgs.mimeo.overridePythonAttrs (upstream: {
      nativeBuildInputs = (upstream.nativeBuildInputs or []) ++ [
        pkgs.copyDesktopItems
      ];
      desktopItems = [
        (pkgs.makeDesktopItem {
          name = "mimeo";
          desktopName = "Mimeo";
          exec = "mimeo %U";
          comment = "Open files by MIME-type or file name using regular expressions.";
        })
      ];
      installPhase = ''
        runHook preInstall
        ${upstream.installPhase}
        runHook postInstall
      '';
    });
    fs.".config/mimeo/associations.txt".symlink.text = lib.concatStringsSep "\n" assocs';
    mime.priority = 20;
    mime.associations."x-scheme-handler/http" = "mimeo.desktop";
    mime.associations."x-scheme-handler/https" = "mimeo.desktop";
  };
}
