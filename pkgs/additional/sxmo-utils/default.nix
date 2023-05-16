{ stdenv
, fetchgit
, gitUpdater
, lib
}:

stdenv.mkDerivation rec {
  pname = "sxmo-utils";
  version = "1.13.0";

  src = fetchgit {
    url = "https://git.sr.ht/~mil/sxmo-utils";
    rev = version;
    hash = "sha256-HNkajPC/spozxRlaP0iMWvOAfriRjl2wo1wdcbVCrkU=";
  };

  postPatch = ''
    sed -i 's@/usr/lib/udev/rules\.d@/etc/udev/rules.d@' Makefile
  '';

  installFlags = [
    "OPENRC=0"
    "DESTDIR=$(out)"
    "PREFIX="
  ];

  passthru.updateScript = gitUpdater { };

  meta = {
    homepage = "https://git.sr.ht/~mil/sxmo-utils";
    description = "Contains the scripts and small C programs that glues the sxmo enviroment together";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ colinsane ];
    platforms = lib.platforms.linux; 
  };
}
