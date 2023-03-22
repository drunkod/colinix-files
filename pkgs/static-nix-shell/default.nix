{ stdenv
, python3
}:

{
  # transform a file which uses `#!/usr/bin/env nix-shell` shebang with a `python3` interpreter
  # into a derivation that can be built statically
  mkPython3Bin = { pname, pyPkgs ? [], srcPath ? pname, ... }@attrs: stdenv.mkDerivation (
    let
      evalPyPkgs = ps: builtins.map (name: ps."${name}") pyPkgs;
      pyEnv = python3.withPackages evalPyPkgs;
      pyPkgsStr = builtins.concatStringsSep " " (builtins.map (p: "ps.${p}") pyPkgs);
    in {
      version = "0.1.0";  # default version
      patchPhase = ''
        substituteInPlace ${srcPath} \
          --replace '#!/usr/bin/env nix-shell' '#!${pyEnv.interpreter}' \
          --replace \
            '#!nix-shell -i python3 -p "python3.withPackages (ps: [ ${pyPkgsStr} ])"' \
            '# nix deps evaluated statically'
      '';
      installPhase = ''
        mkdir -p $out/bin
        mv ${srcPath} $out/bin/${srcPath}
        # ensure that all nix-shell references were substituted
        ! grep nix-shell $out/bin/${srcPath}
      '';
    } // attrs
  );
}
