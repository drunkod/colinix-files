{ stdenv
, runtimeShell
, firejail
}:

stdenv.mkDerivation {
  pname = "sane-sandboxed";
  version = "0.1";
  src = ./.;  #< TODO: should just be `./sane-sandboxed`

  firejail = "${firejail}/bin/firejail";
  inherit runtimeShell;
  postPatch = ''
    substituteAllInPlace sane-sandboxed
  '';

  installPhase = ''
    runHook preInstall
    install -d "$out"
    install -d "$out/bin"
    install -m 755 sane-sandboxed $out/bin/sane-sandboxed
    runHook postInstall
  '';

  meta = {
    description = ''
      helper program to run some other program in a sandbox.
      factoring this out allows:
      1. to abstract over the particular sandbox implementation (bwrap, firejail, ...).
      2. to modify sandbox settings without forcing a rebuild of the sandboxed package.
    '';
    mainProgram = "sane-sandboxed";
  };
}
