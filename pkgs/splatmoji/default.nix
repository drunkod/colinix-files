{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation rec {
  pname = "splatmoji";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "cspeterson";
    repo = "splatmoji";
    rev = "v${version}";
    sha256 = "sha256-fsZ8FhLP3vAalRJWUEi/0fe0DlwAz5zZeRZqAuwgv/U=";
  };

  dontBuild = true;

  # TODO: generate a wrapper so that bin/lib, bin/data aren't linked into the environment?
  installPhase = ''
    mkdir -p $out/bin
    cp splatmoji $out/bin
    cp -R lib $out/bin/lib
    cp -R data $out/bin/data
    cp splatmoji.config $out/bin

    patchShebangs $out/bin/splatmoji
  '';

  meta = with lib; {
    description = "Quickly look up and input emoji and/or emoticons/kaomoji on your GNU/Linux desktop via pop-up menu";
    homepage = "https://github.com/cspeterson/splatmoji";
    license = licenses.mit;
    maintainers = with maintainers; [ colinsane ];
    platforms = with platforms; linux;
  };
  }
