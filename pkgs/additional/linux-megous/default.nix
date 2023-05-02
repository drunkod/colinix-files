{ lib
, buildLinux
, buildPackages
, fetchFromGitHub
, kernelPatches
, modDirVersionArg ? null
, nixosTests
, perl
, ...
} @ args:

with lib;

let
  base = "6.2.0";
  # set to empty if not a release candidate
  rc = "-rc5";
in buildLinux (args // rec {
  version = base + rc;

  # modDirVersion needs to be x.y.z, will automatically add .0 if needed
  modDirVersion = if (modDirVersionArg == null) then concatStringsSep "." (take 3 (splitVersion "${version}.0")) + rc else modDirVersionArg;

  # branchVersion needs to be x.y
  extraMeta.branch = versions.majorMinor version;

  kernelPatches = [
    kernelPatches.bridge_stp_helper
    kernelPatches.request_key_helper
  ];

  src = fetchFromGitHub {
    # HOW TO UPDATE:
    # - `git fetch` from megous' github.
    # - there should be some new tag, like `orange-pi-6.1-blah`. use that.
    # - megi publishes release notes as the most recent commit on any stable branch, so just `git log`.
    # - orange-pi is listed as the "main integration branch".
    #   - specific branches like `pp` (pinephone) are dev branches, and probably less stable.
    owner = "megous";
    repo = "linux";
    rev = "orange-pi-6.2-20230122-1624";
    hash = "sha256-Yma9LwlMEnP0QkUZpEl+UkTGvOWOMANBoDsmcTrPb1s=";
  };
} // (args.argsOverride or { }))
