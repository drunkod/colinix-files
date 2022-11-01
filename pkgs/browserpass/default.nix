{ pkgs
, bash
, fetchFromGitea
, gnused
, lib
, sane-scripts
, sops
, stdenv
, substituteAll
}:

let
  sane-browserpass-gpg = stdenv.mkDerivation {
    pname = "sane-browserpass-gpg";
    version = "0.1.0";
    src = ./.;

    inherit bash gnused sops;
    sane_scripts = sane-scripts;
    installPhase = ''
      mkdir -p $out/bin
      substituteAll ${./sops-gpg-adapter} $out/bin/gpg
      chmod +x $out/bin/gpg
      ln -s $out/bin/gpg $out/bin/gpg2
    '';

  };
in
(pkgs.browserpass.overrideAttrs (upstream: {
  src = fetchFromGitea {
    domain = "git.uninsane.org";
    owner = "colin";
    repo = "browserpass-native";
    rev = "8de7959fa5772aca406bf29bb17707119c64b81e";
    hash = "sha256-ewB1YdWqfZpt8d4p9LGisiGUsHzRW8RiSO/+NZRiQpk=";
  };
  installPhase = ''
    make install

    wrapProgram $out/bin/browserpass \
      --prefix PATH : ${lib.makeBinPath [ sane-browserpass-gpg ]}

    # This path is used by our firefox wrapper for finding native messaging hosts
    mkdir -p $out/lib/mozilla/native-messaging-hosts
    ln -s $out/lib/browserpass/hosts/firefox/*.json $out/lib/mozilla/native-messaging-hosts
  '';
}))
