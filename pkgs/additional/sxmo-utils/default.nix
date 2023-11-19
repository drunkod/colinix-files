{ callPackage
, fetchpatch
}:
let
  patches = [
    (fetchpatch {
      name = "sxmo_migrate: add option to disable configversion checks";
      url = "https://lists.sr.ht/~mil/sxmo-devel/patches/44155/mbox";
      hash = "sha256-ZcUD2UWPM8PxGM9TBnGe8JCJgMC72OZYzctDf2o7Ub0=";
    })

    ## not upstreamable
    (fetchpatch {
      # let NixOS manage the audio daemons (pulseaudio/pipewire)
      name = "sxmo_hook_start: don't start audio daemons";
      url = "https://git.uninsane.org/colin/sxmo-utils/commit/124f8fed85c3ff89ab45f1c21569bcc034d07693.patch";
      hash = "sha256-GteXFZCuRpIXuYrEdEraIhzCm1b4vNJgh3Lmg+Qjeqk=";
    })

    # TODO: send these upstream
    (fetchpatch {
      name = "sxmo_hook_apps: add a few";
      url = "https://git.uninsane.org/colin/sxmo-utils/commit/dd17fd707871961906ed4577b8c89f6128c5f121.patch";
      hash = "sha256-Giek1MbyOtlPccmT8XQkLZWhX+EeJdzWVZtNgcLuTsI=";
    })
    (fetchpatch {
      # experimental patch to launch apps via `swaymsg exec -- `
      # this allows them to detach from sxmo_appmenu.sh (so, `pstree` looks cleaner)
      # and more importantly they don't inherit the environment of sxmo internals (i.e. PATH).
      # suggested by Aren in #sxmo.
      #
      # old pstree look:
      # - sxmo_hook_inputhandler.sh volup_one
      #   - sxmo_appmenu.sh
      #     - sxmo_appmenu.sh applications
      #       - <application, e.g. chatty>
      name = "sxmo_hook_apps: launch apps via the window manager";
      url = "https://git.uninsane.org/colin/sxmo-utils/commit/0087acfecedf9d1663c8b526ed32e1e2c3fc97f9.patch";
      hash = "sha256-YwlGM/vx3ZrBShXJJYuUa7FTPQ4CFP/tYffJzUxC7tI=";
    })
    # (fetchpatch {
    #   name = "sxmo_log: print to console";
    #   url = "https://git.uninsane.org/colin/sxmo-utils/commit/030280cb83298ea44656e69db4f2693d0ea35eb9.patch";
    #   hash = "sha256-dc71eztkXaZyy+hm5teCw9lI9hKS68pPoP53KiBm5Fg=";
    # })
  ];
in {
  latest = callPackage ./common.nix {
    version = "unstable-2023-10-10";
    rev = "c33408abb560dac52de52d878840945c12a75a32";
    hash = "sha256-VYUYN5S6qmsNpxMq7xFfgsGcbjIjqvuj36AG+NeMHTM=";
    inherit patches;
  };
}
