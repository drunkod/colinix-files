{ lib
, firejail
, runCommand
, runtimeShell
}:
{ pkgName, package, vpn ? null, allowedHomePaths ? [], allowedRootPaths ? [], binMap ? {} }:
let
  # XXX: firejail needs suid bit for some (not all) of its sandboxing methods. hence, rely on the user installing it system-wide and call it by suid path.
  # firejailBin = "/run/wrappers/bin/firejail";
  firejailBin = "firejail";

  allowPath = p: [
    "noblacklist ${p}"
    "whitelist ${p}"
  ];
  allowHomePath = p: allowPath ''''${HOME}/${p}'';
  allowPaths = paths: lib.flatten (builtins.map allowPath paths);
  allowHomePaths = paths: lib.flatten (builtins.map allowHomePath paths);

  vpnItems = [
    "net ${vpn.bridgeDevice}"
  ] ++ (builtins.map (addr: "dns ${addr}") vpn.dns);

  firejailItems = [
    # "--quiet"  #< TODO: enable
    # "--tracelog"  # logs blacklist violations to syslog (but default firejail disallows this)
    # "--keep-dev-shm"  #< required for spotify
  ] ++ allowPaths allowedRootPaths
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
      tryFirejailProfile() {
        _maybeProfile="${firejail}/etc/firejail/$1.profile"
        echo "checking for firejail profile at: $_maybeProfile"
        if [ -e "$_maybeProfile" ]; then
          firejailProfilePath="$_maybeProfile"
          firejailProfileName="$1"
          true
        else
          false
        fi
      }
      tryFirejailProfileFromBinMap() {
        case "$1" in
          ${builtins.concatStringsSep "\n" (lib.mapAttrsToList
            (bin: profile: ''
              (${bin})
                tryFirejailProfile "${profile}"
              ;;
            '')
            binMap
          )}
          (*)
            echo "no special-case profile for $1"
            false
            ;;
        esac
      }
      getFirejailProfile() {
        tryFirejailProfileFromBinMap "$1" \
          || tryFirejailProfile "$1" \
          || tryFirejailProfile "${unwrapped.pname or ""}" \
          || tryFirejailProfile "${unwrapped.name or ""}" \
          || tryFirejailProfile "${pkgName}" \
          || (echo "failed to locate firejail profile for $1: aborting!" && false)
      }
      firejailWrap() {
        name="$1"
        getFirejailProfile "$name"
        mv "$out/bin/$name" "$out/bin/.$name-firejailed"
        cat <<EOF >> "$out/bin/$name"
    #!${runtimeShell}
    exec ${firejailBin} \
    --include="${pkgName}.local" \
    --profile=":$firejailProfileName" \
    --join-or-start="$firejailProfileName" \
    -- "$out/bin/.$name-firejailed" "\$@"
    EOF
        chmod +x "$out/bin/$name"
      }

      for _p in $(ls "$out/bin/"); do
        firejailWrap "$_p"
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
      checkSandboxed = runCommand "${unwrapped.name or unwrapped.pname or "unknown"}-check-sandboxed" {} ''
        # this pseudo-package gets "built" as part of toplevel system build.
        # if the build is failing here, that means the program isn't properly sandboxed:
        # make sure that "postFixup" gets called as part of the package's build script
        test -f "${packageWrapped}/nix-support/sandboxed" \
          && touch "$out"
      '';
      firejailLocalConfig = builtins.concatStringsSep "\n" firejailItems;
    };
  });
in
  packageWrapped
