{ stdenv
, bc
, bemenu
, bonsai
, conky
, dbus
, fetchgit
, fetchpatch
, gitUpdater
, gnugrep
, gojq
, grim
, inotify-tools
, j4-dmenu-desktop
, jq
, lib
, libnotify
, lisgd
, makeBinaryWrapper
, mako
, mepo
, modemmanager
, nettools
, playerctl
, procps
, pulseaudio
, rsync
, scdoc
, sfeed
, superd
, sway
, swayidle
, wob
, wvkbd
, xdg-user-dirs
, xdotool
}:

let
  # anything which any sxmo script or default hook in this package might invoke
  runtimeDeps = [
    bc
    bemenu
    bonsai
    conky
    dbus
    # dmenu  # or dmenu-wayland? only used on x11?
    gnugrep
    gojq
    grim
    inotify-tools
    j4-dmenu-desktop
    jq
    libnotify
    lisgd
    mako
    mepo  # mepo_ui_central_menu.sh
    modemmanager  # mmcli
    nettools  # netstat
    playerctl
    procps  # pgrep
    pulseaudio  # pactl
    sfeed
    superd
    sway
    swayidle
    wob
    wvkbd
    xdg-user-dirs

    # X11 only?
    xdotool
  ];
in
stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "1.14.2";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    hash = "sha256-1bGCUhf/bt9I8BjG/G7sjYBzLh28iZSC20ml647a3J4=";
  };

  patches = [
    # needed for basic use:
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
      url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42880/mbox";
      hash = "sha256-tAMPBb6vwzj1dFMTEaqrcCJU6FbQirwZgB0+tqW3rQA=";
    })
    ./0004-no-busybox.patch
    # wanted to fix/silence some non-fatal errors
    ./0005-system-audio.patch
    ./0007-workspace-wrapping.patch

    # personal (but upstreamable) preferences:
    (fetchpatch {
      # merged post 1.14.2
      # sxmo_hook_lock: allow configuration of auto-screenoff timeout v1
      url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42443/mbox";
      hash = "sha256-c4VySbVJgsbh2h+CnCgwWWe5WkAregpYFqL8n3WRXwY=";
    })
    (fetchpatch {
      # Make config gesture toggle persistent
      url = "https://lists.sr.ht/~mil/sxmo-devel/patches/42876/mbox";
      hash = "sha256-Oa0MI0Kt9Xgl5L1KarHI6Yn4+vpRxUSujB1iY4hlK9c=";
    })
    ./0104-full-auto-rotate.patch
    ./0105-more-apps.patch
    # ./0106-no-restart-lisgd.patch
  ];

  postPatch = ''
    sed -i 's@/usr/lib/udev/rules\.d@/etc/udev/rules.d@' Makefile
    sed -i "s@/etc/profile\.d/sxmo_init.sh@$out/etc/profile.d/sxmo_init.sh@" scripts/core/*.sh
    sed -i "s@/usr/bin/@@g" scripts/core/sxmo_version.sh
    sed -i 's:ExecStart=/usr/bin/:ExecStart=/usr/bin/env :' configs/superd/services/*.service
  '';

  nativeBuildInputs = [
    makeBinaryWrapper
    scdoc
  ];

  installFlags = [
    "OPENRC=0"
    "DESTDIR=$(out)"
    "PREFIX="
  ];

  # we don't wrap sxmo_common.sh or sxmo_init.sh
  # which is unfortunate, for non-sxmo-utils files that might source though.
  # if that's a problem, could inject a PATH=... line into them with sed.
  postInstall = ''
    for f in \
      $out/bin/*.sh \
      $out/share/sxmo/default_hooks/desktop/sxmo_hook_*.sh \
      $out/share/sxmo/default_hooks/one_button_e_reader/sxmo_hook_*.sh \
      $out/share/sxmo/default_hooks/three_button_touchscreen/sxmo_hook_*.sh \
      $out/share/sxmo/default_hooks/sxmo_hook_*.sh \
    ; do
      case $(basename $f) in
        (sxmo_common.sh|sxmo_deviceprofile_*.sh|sxmo_hook_icons.sh|sxmo_init.sh)
          # these are sourced by other scripts: don't wrap them else the `exec` in the wrapper breaks the outer script
        ;;
        (*)
          wrapProgram "$f" \
            --prefix PATH : "${lib.makeBinPath runtimeDeps}"
        ;;
      esac
    done
  '';

  passthru = {
    providedSessions = [ "sxmo" "swmo" ];
    updateScript = gitUpdater { };
  };

  meta = {
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ colinsane ];
    platforms = lib.platforms.linux; 
  };
}
