{ stdenv
, mepo
, fetchFromSourcehut
, zig_0_9
}:
(mepo.override {
  inherit stdenv;  #< for easier `override` in cross.nix
  zig = zig_0_9;
}).overrideAttrs (orig: rec {
  version = "1.1";
  src = fetchFromSourcehut {
    owner = "~mil";
    repo = "mepo";
    rev = version;
    hash = "sha256-OIZ617QLjiTiDwcsn0DnRussYtjDkVyifr2mdSqA98A=";
  };
})
