{ stdenv
, lib
, fetchFromSourcehut
, gitUpdater
, hare
, hare-ev
, hare-json
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

  patches = [
    ./0001-cross-compile.patch
  ];

  postPatch = lib.optionalString stdenv.isAarch64 ''
    sed -i 's/hare build/hare build -t aarch64/g' Makefile
  '';

  nativeBuildInputs = [
    hare
    hare-ev
    hare-json
  ];

  preConfigure = ''
    export HARECACHE=$(mktemp -d)
    # export AR=/bin/foob
    # export AR=$${binutils-unwrapped}/bin/ar
    # export AR="$${coreutils}/bin/echo --"
    # export ARFLAGS="--"
    # FIX "ar: invalid option -- '/'" bug in older versions of hare.
    # should be safe to remove once updated past 2023/05/22-ish.
    export ARFLAGS="-csr"
  '';

  # makeFlags = [
  #   ''HAREFLAGS="-t aarch64"''
  #   ''QBEFlags="-t arm64"''
  #   # "ARCH=aarch64"
  #   "all"
  # ];

  installFlags = [
    "PREFIX="
    "DESTDIR=$(out)"
    # ''HAREFLAGS="-t aarch64"''
    # ''QBEFlags="-t arm64"''
  ];

  # ARCH = "aarch64";
  # HAREFLAGS = "-t aarch64";
  # QBEFLAGS = "-t arm64";
  # AARCH64_AR = "/bin/foob";

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "Bonsai is a Finite State Machine structured as a tree";
    homepage = "https://git.sr.ht/~stacyharper/bonsai";
    license = licenses.agpl3;
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
  };
}
