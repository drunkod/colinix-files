{ makeSetupHook
, cargoDocset
}:
makeSetupHook {
  name = "cargo-docset-hook";
  propagatedBuildInputs = [
    cargoDocset
  ];
} ./hook.sh
