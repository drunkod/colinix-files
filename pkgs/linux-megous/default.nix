{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

let
  base = "6.1.0";
  # set to empty if not a release candidate
  rc = "-rc7";
in buildLinux (args // rec {
  version = base + rc;

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) + rc else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    rev = "orange-pi-6.1-20221128-1027";
    hash = "sha256-kEujs4v5rPHPYy4YLyEWHa1Bu0sxoXLgSvmOH9QPWos=";
  };
} // (args.argsOverride or { }))
