{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

buildLinux (args // rec {
  version = "6.0.2";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    # branch: orange-pi-6.0
    rev = "2683672a2052ffda995bb987fa62a1abe8424ef4";
    hash = "sha256-hL/SbLgaTk/CqFLFrAK/OV9/OS20O42zJvSScsvWBQk=";
  };
} // (args.argsOverride or { }))
