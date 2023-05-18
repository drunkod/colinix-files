{ stdenv
, lib
, fetchFromSourcehut
, gitUpdater
, hare
}:

stdenv.mkDerivation rec {
  pname = "bonsai";
  version = "1.0.0";

  src = fetchFromSourcehut {
    owner = "~stacyharper";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-jOtFUpl2/Aa7f8JMZf6g63ayFOi+Ci+i7Ac63k63znc=";
  };

  nativeBuildInputs = [
    hare
  ];

  preConfigure = ''
    export HARECACHE=$(mktemp -d)
  '';

  installFlags = [ "PREFIX=" "DESTDIR=$(out)" ];

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "Bonsai is a Finite State Machine structured as a tree";
    homepage = "https://git.sr.ht/~stacyharper/bonsai";
    license = licenses.agpl3;
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
    broken = true;  # needs hare-json. see: <https://gitlab.alpinelinux.org/alpine/aports/-/merge_requests/40949/diffs>
  };
}
