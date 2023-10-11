{ static-nix-shell
, iw
, moreutils
, wirelesstools
}:

static-nix-shell.mkPython3Bin {
  pname = "rtl8723cs-wowlan";
  src = ./.;
  pkgs = {
    inherit iw moreutils wirelesstools;
  };
}

