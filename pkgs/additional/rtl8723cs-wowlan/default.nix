{ static-nix-shell
, iw
, wirelesstools
}:

static-nix-shell.mkPython3Bin {
  pname = "rtl8723cs-wowlan";
  src = ./.;
  pkgs = {
    inherit iw wirelesstools;
  };
}

