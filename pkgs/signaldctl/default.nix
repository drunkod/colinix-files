{ lib
, buildGoModule
, fetchFromGitLab }:

buildGoModule rec {
  pname = "signaldctl";
  version = "0.6.1";
  src = fetchFromGitLab {
    owner = "signald";
    repo = "signald-go";
    rev = "v${version}";
    hash = "sha256-lMJyr4BPZ8V2f//CUkr7CVQ6o8nRyeLBHMDEyLcHSgQ=";
  };

  vendorHash = "sha256-LGIWAVhDJCg6Ox7U4ZK15K8trjsvSZm4/0jNpIDmG7I=";

  meta = with lib; {
    description = "A golang library for communicating with signald";
    homepage = "https://signald.org/signaldctl/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ colinsane ];
    platforms = [ "x86_64-linux" "aarch64-linux" ];
  };
}
