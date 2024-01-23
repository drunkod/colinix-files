{ lib
, buildPackages
, firejail
, runCommand
, runtimeShell
, sane-sandboxed
, writeTextFile
}:
{ pkgName, package, vpn ? null, allowedHomePaths ? [], allowedRootPaths ? [], binMap ? {} }:
let
  sane-sandboxed' = sane-sandboxed.meta.mainProgram;  #< load by bin name to reduce rebuilds

  allowPath = p: [
    "--sane-sandbox-path"
    p
  ];
  allowHomePath = p: [
    "--sane-sandbox-home-path"
    p
  ];
  allowPaths = paths: lib.flatten (builtins.map allowPath paths);
  allowHomePaths = paths: lib.flatten (builtins.map allowHomePath paths);

  vpnItems = [
    "--sane-sandbox-net"
    vpn.bridgeDevice
  ] ++ lib.flatten (builtins.map (addr: [
    "--sane-sandbox-dns"
    addr
  ]) vpn.dns);

  sandboxFlags = allowPaths allowedRootPaths
    ++ allowHomePaths allowedHomePaths
    ++ lib.optionals (vpn != null) vpnItems;

  # two ways i could wrap a package in a sandbox:
  # 1. package.overrideAttrs, with `postFixup`.
  # 2. pkgs.symlinkJoin, or pkgs.runCommand, creating an entirely new package which calls into the inner binaries.
  #
  # no.2 would require special-casing for .desktop files, to ensure they refer to the jailed version.
  # no.1 may require extra care for recursive binaries, or symlink-heavy binaries (like busybox)
  #   but even no.2 has to consider such edge-cases, just less frequently.
  # no.1 may bloat rebuild times.
  #
  # ultimately, no.1 is probably more reliable, but i expect i'll factor out a switch to allow either approach -- particularly when debugging package buld failures.
  package' = if package.override.__functionArgs ? runCommand then
    package.override {
      runCommand = name: env: cmd: runCommand name env (cmd + lib.optionalString (name == package.name) ''
        # if the package is a runCommand (common for wrappers), then patch it to call our `postFixup` hook, first
        runHook postFixup
      '');
    }
  else
    package
  ;

  packageWrapped = package'.overrideAttrs (unwrapped: {
    postFixup = (unwrapped.postFixup or "") + ''
      getProfileFromBinMap() {
        case "$1" in
          ${builtins.concatStringsSep "\n" (lib.mapAttrsToList
            (bin: profile: ''
              (${bin})
                echo "${profile}"
              ;;
            '')
            binMap
          )}
          (*)
            ;;
        esac
      }
      sandboxWrap() {
        _name="$1"
        _profileFromBinMap="$(getProfileFromBinMap $_name)"

        _profiles=("$_profileFromBinMap" "$_name" "${pkgName}" "${unwrapped.pname or ""}" "${unwrapped.name or ""}")
        # filter to just the unique profiles
        _profileArgs=()
        for _profile in "''${_profiles[@]}"; do
          if [ -n "$_profile" ] && ! [[ " ''${_profileArgs[@]} " =~ " $_profile " ]]; then
            _profileArgs+=("--sane-sandbox-profile" "$_profile")
          fi
        done

        mv "$out/bin/$_name" "$out/bin/.$_name-sandboxed"
        cat <<EOF >> "$out/bin/$_name"
    #!${runtimeShell}
    exec ${sane-sandboxed'} \
    ''${_profileArgs[@]} \
    "$out/bin/.$_name-sandboxed" "\$@"
    EOF
        chmod +x "$out/bin/$_name"
      }

      for _p in $(ls "$out/bin/"); do
        sandboxWrap "$_p"
      done

      # stamp file which can be consumed to ensure this wrapping code was actually called.
      mkdir -p $out/nix-support
      touch $out/nix-support/sandboxed
    '';
    meta = (unwrapped.meta or {}) // {
      # take precedence over non-sandboxed versions of the same binary.
      priority = ((unwrapped.meta or {}).priority or 0) - 1;
    };
    passthru = (unwrapped.passthru or {}) // {
      checkSandboxed = runCommand "${pkgName}-check-sandboxed" {} ''
        # this pseudo-package gets "built" as part of toplevel system build.
        # if the build is failing here, that means the program isn't properly sandboxed:
        # make sure that "postFixup" gets called as part of the package's build script
        test -f "${packageWrapped}/nix-support/sandboxed" \
          && touch "$out"
      '';
      sandboxProfiles = writeTextFile {
        name = "${pkgName}-sandbox-profiles";
        destination = "/share/sane-sandboxed/profiles/${pkgName}.profile";
        text = builtins.concatStringsSep "\n" sandboxFlags;
      };
    };
  });
in
  packageWrapped
