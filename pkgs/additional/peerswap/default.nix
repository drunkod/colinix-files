# based on: <https://github.com/fort-nix/nix-bitcoin/pull/462>
{ lib
, stdenv
, fetchFromGitHub
, buildGoModule
}:

buildGoModule rec {
  pname = "peerswap";
  # the don't do releases yet
  version = "unstable-20240111";

  src = fetchFromGitHub {
    owner = "ElementsProject";
    repo = "peerswap";
    rev = "4d1270b9dd2986ce683f61e684996b5961b05db0";
    hash = "sha256-lnmimWtkc2hy+SPzXMeybetZldSLbcPEN5apKGFYo7k=";
  };

  subPackages = [
    "cmd/peerswaplnd/peerswapd"
    "cmd/peerswaplnd/pscli"
    "cmd/peerswap-plugin"  # this becomes the actual `peerswap` binary
  ];

  vendorHash = "sha256-OOwXWsFVxieOtzF7arXVNeWo4YB/EQbxQMAIxDVIhfg=";
  proxyVendor = true;

  meta = with lib; {
    description = "PeerSwap enables Lightning Network nodes to balance their channels by facilitating atomic swaps with direct peers.";
    homepage = "https://peerswap.dev";
    maintainers = with maintainers; [ colinsane ];
    license = licenses.mit;
    platforms = platforms.linux;
  };
}
