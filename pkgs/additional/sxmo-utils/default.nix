{ stdenv
, callPackage
, fetchgit
, gitUpdater
, lib
}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "1.14.1";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    hash = "sha256-UcJid1fi3Mgu32dCqlI9RQYnu5d07MMwW3eEYuYVBw4=";
  };

  patches = [
    ./0001-group-differs-from-user.patch
    ./0002-ensure-log-dir.patch
    ./0003-fix-xkb-paths.patch
  ];

  postPatch = ''
    sed -i 's@/usr/lib/udev/rules\.d@/etc/udev/rules.d@' Makefile
    sed -i "s@/etc/profile\.d/sxmo_init.sh@$out/etc/profile.d/sxmo_init.sh@" scripts/core/*.sh
    sed -i "s@/usr/bin/@@g" scripts/core/sxmo_version.sh
  '';

  installFlags = [
    "OPENRC=0"
    "DESTDIR=$(out)"
    "PREFIX="
  ];

  passthru = {
    providedSessions = [ "sxmo" "swmo" ];
    updateScript = gitUpdater { };
    hooks = callPackage ./hooks.nix { };
  };

  meta = {
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ colinsane ];
    platforms = lib.platforms.linux; 
  };
}
