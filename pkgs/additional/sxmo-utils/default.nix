{ callPackage
, fetchpatch
}:
let
  patches = {
    merged = [
      (fetchpatch {
        # merged post 1.14.2
        # [1/2] sxmo_init: behave well when user's primary group differs from their name
        # [2/2] sxmo_init: ensure XDG_STATE_HOME exists
        url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42309/mbox";
        hash = "sha256-GVWJWTccZeaKsVtsUyZFYl9/qEwJ5U7Bu+DiTDXLjys=";
      })
      (fetchpatch {
        # merged post 1.14.2
        # sxmo_hook_block_suspend: don't assume there's only one MPRIS player
        url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42441/mbox";
        hash = "sha256-YmkJ4JLIG/mHosRlVQqvWzujFMBsuDf5nVT3iOi40zU=";
      })
      (fetchpatch {
        # merged post 1.14.2
        # i only care about patch no. 2
        # [1/2] suspend toggle: silence rm failure noise
        # [2/2] config: fix keyboard files location
        name = "multipatch: 42880";
        url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42880/mbox";
        hash = "sha256-tAMPBb6vwzj1dFMTEaqrcCJU6FbQirwZgB0+tqW3rQA=";
      })
      (fetchpatch {
        # merged post 1.14.2
        name = "Switch from light to brightnessctl";
        url = "https://git.sr.ht/~mil/sxmo-utils/commit/d0384a7caed036d25228fa3279c36c0230795e4a.patch";
        hash = "sha256-/UlcuEI5cJnsqRuZ1zWWzR4dyJw/zYeB1rtJWFeSGEE=";
      })
      (fetchpatch {
        # merged post 1.14.2
        name = "sxmo_hook_lock: allow configuration of auto-screenoff timeout v1";
        url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42443/mbox";
        hash = "sha256-c4VySbVJgsbh2h+CnCgwWWe5WkAregpYFqL8n3WRXwY=";
      })
      (fetchpatch {
        # merged post 1.14.2
        name = "sxmo_wmmenu: respect SXMO_WORKSPACE_WRAPPING";
        url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42698/mbox";
        hash = "sha256-TrTlrthrpYdIMC8/RCMNaB8PcGQgtya/h2/uLNQDeWs=";
      })
    ];
    unmerged = [
      # (fetchpatch {
      #   XXX: doesn't apply cleanly to 1.14.2 release
      #   # Don't wait for led or status bar in state change hooks
      #   # - significantly decreases the time between power-button state transitions
      #   url = "https://lists.sr.ht/~mil/sxmo-devel/patches/43109/mbox";
      #   hash = "sha256-4uR2u6pa62y6SaRHYRn15YGDPILAs7py0mPbAjsgwM4=";
      # })
      (fetchpatch {
        name = "Make config gesture toggle persistent";
        url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42876/mbox";
        hash = "sha256-Oa0MI0Kt9Xgl5L1KarHI6Yn4+vpRxUSujB1iY4hlK9c=";
      })

      ## TODO: send these upstream
      (fetchpatch {
        name = "sxmo_hook_apps: add a few";
        url = "https://git.uninsane.org/colin/sxmo-utils/commit/d39f0956859e41f408ccbdc0bff0b986bc483cdd.patch";
        hash = "sha256-AVdvfzGmV/RydafBnrQsRJP42eU9VsFRc2/wgPUWocs=";
      })
      (fetchpatch {
        name = "sxmo_migrate: add option to disable configversion checks";
        url = "https://git.uninsane.org/colin/sxmo-utils/commit/8949c64451973212a8aa50375396ec375c676d1e.patch";
        hash = "sha256-Okjjwa2FBJOrDVZGrfaUEPGQY749+V4w0gALIBp50hQ=";
      })
      (fetchpatch {
        name = "Makefile: use SYSCONFDIR instead of hardcoding /etc";
        url = "https://git.uninsane.org/colin/sxmo-utils/commit/bbad10e074c335710e5ab171a0b1d96dddf160ed.patch";
        hash = "sha256-jqxzGLjYXuJV6NB/4zsPdjuzNVyUCxPSlGMDW5XetZ8=";
      })

      ## these might or might not be upstream-worthy
      ./0104-full-auto-rotate.patch
      # ./0106-no-restart-lisgd.patch

      ## not upstreamable
      # let NixOS manage the audio daemons (pulseaudio/pipewire)
      ./0005-system-audio.patch
    ];
  };
in {
  stable = callPackage ./common.nix {
    version = "1.14.2";
    hash = "sha256-1bGCUhf/bt9I8BjG/G7sjYBzLh28iZSC20ml647a3J4=";
    patches = patches.merged ++ patches.unmerged;
  };
  latest = callPackage ./common.nix {
    version = "unstable-2023-08-11";
    rev = "095678e77fcd9ad2c1ed1ffc98fc66d2f19ccf64";
    hash = "sha256-TGj3zcwW7aS/5KXcUt0jyESZcNqHY/JZ5HCTgT7Qsbk=";
    patches = patches.unmerged;
  };
}
