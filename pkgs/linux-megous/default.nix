{ lib, buildPackages, fetchFromGitHub, perl, buildLinux, nixosTests, modDirVersionArg ? null, ... } @ args:

with lib;

buildLinux (args // rec {
  version = "6.0.0-rc4";

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) + "-rc4" else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  src = fetchFromGitHub {
    owner = "megous";
    repo = "linux";
    # branch: orange-pi-6.0
    rev = "6ada3caab0b37968f1257b3ea75e5b0466a77162";
    sha256 = "sha256-jIhOE0ZMuoJm7NqAEJ4OTNLHN/h8i4cOphcw3le7RSw=";
  };
} // (args.argsOverride or { }))
