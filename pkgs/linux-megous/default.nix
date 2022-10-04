{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

buildLinux (args // rec {
  version = "6.0.0";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    # branch: orange-pi-6.0
    rev = "b16232c6156de17e1dfdb63fdaea8e317baa07a7";
    sha256 = "sha256-Tb05IQKFdX/T7elGNnXTLVmgGLvXoeBFBq/8Q7jQhX0=";
  };
} // (args.argsOverride or { }))
