{ makeSetupHook
, cargo
, cargoDocset
}:
makeSetupHook {
  name = "cargo-docset-hook";
  propagatedBuildInputs = [
    cargo cargoDocset
  ];
} ./hook.sh
