# Fractal: GTK4 instant messenger client for the Matrix protocol
#
# very susceptible to state corruption during hard power-cycles.
# if it stalls while launching, especially with a brief message at bottom
# "unable to open store"
# then:
# - remove ~/.local/share/stable
#   - this might give I/O error, in which case remove the corresponding path under
#     /nix/persist/home/colin/private (which can be found by correlating timestamps/sizes with that in ~/private/.local/share/stable).
# - reboot (maybe necessary).
# - TODO: unsure if necessary to delete the keyring entry and re-login, re-verify with other session, or not.
#   - process above may leave you unable to send/receive encrypted messages.
{ config, lib, pkgs, ... }:
let
  cfg = config.sane.programs.fractal;
in
{
  sane.programs.fractal = {
    package = pkgs.fractal-nixified;
    # package = pkgs.fractal-latest;
    # package = pkgs.fractal-next;

    configOption = with lib; mkOption {
      default = {};
      type = types.submodule {
        options.autostart = mkOption {
          type = types.bool;
          default = true;
        };
      };
    };

    persist.private = [
      # XXX by default fractal stores its state in ~/.local/share/<build-profile>/<UUID>.
      ".local/share/hack"    # for debug-like builds
      ".local/share/stable"  # for normal releases
    ];

    suggestedPrograms = [ "gnome-keyring" ];

    services.fractal = {
      description = "auto-start and maintain fractal Matrix connection";
      wantedBy = lib.mkIf cfg.config.autostart [ "default.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/fractal";
        Type = "simple";
        Restart = "always";
        RestartSec = "20s";
      };
      # environment.G_MESSAGES_DEBUG = "all";
    };
  };
}
