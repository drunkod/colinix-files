{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

buildLinux (args // rec {
  version = "5.19.8";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    # branch: orange-pi-5.19
    rev = "b8fd52d433a566c54a58fcec65fb479efd15bff2";
    sha256 = "sha256-tnTMpQ+gRcq4haaVk6TVMHCYxM5vGp1ZAiMIzkskxpk=";
  };
} // (args.argsOverride or { }))
