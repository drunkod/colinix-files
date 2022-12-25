{ lib
, browserpass
, bash
, fetchFromGitea
, gnused
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
(browserpass.overrideAttrs (upstream: {
  src = fetchFromGitea {
    domain = "git.uninsane.org";
    owner = "colin";
    repo = "browserpass-native";
    # don't forcibly append '.gpg'
    rev = "85bdb08379c03297c1236f66e8764160c922d397";
    hash = "sha256-SEfihU+GreWhYfLVr7tTnMCo6Iq20a78F8iVbycOQUQ=";
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
