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
  version = "1.0.2";

  src = fetchFromSourcehut {
    owner = "~stacyharper";
    repo = "bonsai";
    rev = "v${version}";
    hash = "sha256-Yosf07KUOQv4O5111tLGgI270g0KVGwzdTPtPOsTcP8=";
  };

  postPatch = ''
    substituteInPlace Makefile \
      --replace 'hare build' 'hare build $(HARE_TARGET_FLAGS)'
  '';

  env.HARE_TARGET_FLAGS =
    if stdenv.hostPlatform.isAarch64 then
      "-a aarch64"
    else if stdenv.hostPlatform.isRiscV64 then
      "-a riscv64"
    else if stdenv.hostPlatform.isx86_64 then
      "-a x86_64"
    else
      "";

  nativeBuildInputs = [
    hare
  ];

  buildInputs = [
    hare-ev
    hare-json
  ];

  preConfigure = ''
    export HARECACHE=$(mktemp -d)
  '';

  installFlags = [ "PREFIX=$(out)" ];

  doCheck = true;

  passthru.updateScript = gitUpdater {
    rev-prefix = "v";
  };

  meta = with lib; {
    description = "Finite State Machine structured as a tree";
    homepage = "https://git.sr.ht/~stacyharper/bonsai";
    license = licenses.agpl3;
    maintainers = with maintainers; [ colinsane ];
    platforms = platforms.linux;
  };
}
