{ stdenv
, bc
, bemenu
, bonsai
, conky
, fetchgit
, gitUpdater
, gojq
, inotify-tools
, j4-dmenu-desktop
, jq
, lib
, libnotify
, lisgd
, makeWrapper
, mako
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
  runtimeDeps = [
    bc
    bemenu
    bonsai
    conky
    gojq
    inotify-tools
    j4-dmenu-desktop
    jq
    libnotify
    lisgd
    mako
    pulseaudio
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
    ./0001-group-differs-from-user.patch
    ./0002-ensure-log-dir.patch
    ./0003-fix-xkb-paths.patch
    ./0004-no-busybox.patch

    # personal preferences:
    ./0104-full-auto-rotate.patch
  ];

  postPatch = ''
    sed -i 's@/usr/lib/udev/rules\.d@/etc/udev/rules.d@' Makefile
    sed -i "s@/etc/profile\.d/sxmo_init.sh@$out/etc/profile.d/sxmo_init.sh@" scripts/core/*.sh
    sed -i "s@/usr/bin/@@g" scripts/core/sxmo_version.sh
    sed -i 's:ExecStart=/usr/bin/:ExecStart=/usr/bin/env :' configs/superd/services/*.service

    # apply customizations
    # - xkb_mobile_normal_buttons:
    #   - on devices where volume is part of the primary keyboard (e.g. thinkpad), we want to avoid overwriting the default map
    #   - this provided map is the en_US 105 key map
    ${rsync}/bin/rsync -rlv ${./customization}/ ./
  '';

  nativeBuildInputs = [
    makeWrapper
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
      $out/etc/profile.d/sxmo_init.sh \
      $out/sxmo/default_hooks/desktop/sxmo_hook_*.sh \
      $out/sxmo/default_hooks/one_button_e_reader/sxmo_hook_*.sh \
      $out/sxmo/default_hooks/three_button_touchscreen/sxmo_hook_*.sh \
      $out/sxmo/default_hooks/sxmo_hook_*.sh \
      $out/sxmo/profile.d/sxmo_init.sh \
    ; do
      if [ $(basename $f) != sxmo_common.sh -a $(basename $f) != sxmo_init.sh ]; then
        wrapProgram "$f" \
          --prefix PATH : "${lib.makeBinPath runtimeDeps}"
      fi
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
