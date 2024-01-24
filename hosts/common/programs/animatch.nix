# debug with:
# - `animatch --debug`
# - `gdb animatch`
# try:
# - `animatch --fullscreen`
# - `animatch --windowed`
# the other config options (e.g. verbose logging -- which doesn't seem to do anything) have to be configured via .ini file
# ```ini
# # ~/.config/Holy Pangolin/Animatch/SuperDerpy.ini
# [SuperDerpy]
# debug=1
# disableTouch=1
# [game]
# verbose=1
# ```
{ pkgs, ... }:
{
  sane.programs.animatch = {
    packageUnwrapped = with pkgs; animatch.override {
      # allegro has no native wayland support, and so by default crashes when run without Xwayland.
      # enable the allegro SDL backend, and achieve Wayland support via SDL's Wayland support.
      # TODO: see about upstreaming this to nixpkgs?
      allegro5 = allegro5.overrideAttrs (upstream: {
        buildInputs = upstream.buildInputs ++ [
          SDL2
        ];
        cmakeFlags = upstream.cmakeFlags ++ [
          "-DALLEGRO_SDL=on"
        ];
      });
    };
    sandbox.method = "bwrap";
    persist.byStore.plaintext = [
      # game progress
      # i'm not sure which of these is correct. i think it might actually use both of these, in different places.
      # but it's probably the ~/.config one?
      ".config/Holy Pangolin/Animatch"
      ".local/share/Holy Pangolin/Animatch"
    ];
  };
}
