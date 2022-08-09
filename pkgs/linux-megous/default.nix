{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

buildLinux (args // rec {
  version = "5.18.14";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    # branch: orange-pi-5.18
    rev = "3ef835b665191e4833ae1363245be48e96013df6";
    sha256 = "sha256-nQsBXeGLZhpem1p7Vnc8z7XB354AO1mn7VTj/hH5twY=";
  };
} // (args.argsOverride or { }))
