# Flare is a 3rd-party GTK4 Signal app.
# UI is effectively a clone of Fractal.
# compatibility:
# - desko: works fine. pairs, and exchanges contact list (but not message history) with the paired device. exchanges future messages fine.
# - moby (cross compiled flare-signal-nixified): nope. it pairs, but can only *receive* messages and never *send* them.
#   - even `rsync`ing the data and keyrings from desko -> moby, still fails in that same manner.
#   - console shows error messages. quite possibly an endianness mismatch somewhere
# - moby (partially-emulated flare-signal): works! pairs and can send/receive messages, same as desko.
{ pkgs, ... }:
{
  sane.programs.flare-signal = {
    # package = pkgs.flare-signal-nixified;
    package = pkgs.flare-signal;
    persist.private = [
      # everything: conf, state, files, all opaque
      ".local/share/flare"
      # also persists a secret in ~/.local/share/keyrings. reset with:
      # - `secret-tool search --all --unlock 'xdg:schema' 'de.schmidhuberj.Flare'`
      # - `secret-tool clear 'xdg:schema' 'de.schmidhuberj.Flare'`
      # and it persists some dconf settings (e.g. device name). reset with:
      # - `dconf reset -f /de/schmidhuberj/Flare/`.
    ];
  };
}
