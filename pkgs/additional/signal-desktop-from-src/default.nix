# arch package:
# - <https://gitlab.archlinux.org/archlinux/packaging/packages/signal-desktop/-/blob/main/PKGBUILD?ref_type=heads>
# - builds with `yarn generate; yarn build`
#
# signal uses typescript, javascript, and electron
# - no node, npm
#
# nix provides:
# - yarn2nix
# - mkYarnPackage
# - mkYarnModules, and then invoke the rest of the build manually
#   - that's what i do in browserpass-extension
#
# comment about the "Couldn't find any versions ..." bug:
# - <https://discourse.nixos.org/t/mkyarnpackage-lockfile-has-incorrect-entry/21586/3>
# - "don't use mkYarnPackage"
#
# build failure: "Error: Could not detect abi for version 26.4.0 and runtime electron.  Updating "node-abi" might help solve this issue if it is a new release of electron"
# - signal 6.36.0 pins node-abi to 2.21.0, which only goes up to electron 13!!
# - signal-desktop also uses node-abi 2.21.0...
# - this seems to actually be a recoverable error? i don't think it's the point at which it's bailing.
#
# build failure:
# Fusing electron at /build/source/dist/linux-unpacked/signal-desktop inspect-arguments=false
# ⨯ EACCES: permission denied, open '/build/source/dist/linux-unpacked/signal-desktop'  failedTask=build stackTrace=Error: EACCES: permission denied, open '/build/source/dist/linux-unpacked/signal-desktop'
# - this file DOES exist. it's executable (555).
# - segfaults when invoked:
#   ```
#   Thread 1 "signal-desktop" received signal SIGTRAP, Trace/breakpoint trap.
#   0x000055555c2f6eb0 in sandbox::SetuidSandboxHost::GetSandboxBinaryPath() ()
#   (gdb) c
#   Continuing.
#
#   Thread 1 "signal-desktop" received signal SIGILL, Illegal instruction.
#   0x000055555c2f6eb0 in sandbox::SetuidSandboxHost::GetSandboxBinaryPath() ()
#   (gdb) c
#   Continuing.
#   [Thread 0x7ffff39626c0 (LWP 1805441) exited]
#
#   Program terminated with signal SIGILL, Illegal instruction.
#   The program no longer exists.
#   (gdb)
#   ```
# - this file is created by the yarn build:electron invocation: it doesn't exist after build:esbuild:prod.
# - running this step a second time produces the identical error
# - running it a second time, with `chmod 777` in between produces identical error
# - /build/source/dist/linux-unpacked/ is simply a copy of /nix/store/2harqvx80ddx7p9y26m1zds2hk4br298-electron-25.9.1/libexec/electron/ but with `electron` renamed `signal-desktop`.
#   - i think it's trying to do some edit-in-place thing
#
#
{ lib
# , fetchYarnDeps
# , mkYarnPackage
# , mkYarnModules
, callPackage
# , electron_26
, electron_25
# , electron
, fetchFromGitHub
, fixup_yarn_lock
, makeWrapper
, nodejs
, python3
, srcOnly
, stdenv
, yarn
}:
let
  # package.json locks electron to 25.8.4
  # element-desktop uses electron_26
  # nixpkgs has `electron` defaulted to electron_27
  # alpine builds signal-desktop using its default electron version, i.e. 27.0.2
  # electron = electron_26;
  electron = electron_25;
  # nodeSources = srcOnly nodejs;
in
# mkYarnPackage rec {
#   pname = "signal-desktop-from-src";
#   version = "6.36.0";
#   src = fetchFromGitHub {
#     owner = "signalapp";
#     repo = "Signal-Desktop";
#     rev = "v${version}";
#     hash = "sha256-86x6OeQAMN5vhLaAphnAfSWeRgUh0wAeZFzxue8otDQ=";
#   };
# 
#   # to update:
#   # - `cp ~/ref/repos/signalapp/Signal-Desktop/{package.json,yarn.lock} .`
#   # - `nix run '.#yarn2nix' > yarn.nix`
#   packageJSON = ./package.json;
#   yarnLock = ./yarn.lock;
#   # yarnLock = "${src}/yarn.lock";
#   yarnNix = ./yarn.nix;
#   offlineCache = fetchYarnDeps {
#     yarnLock = "${src}/yarn.lock";
#     hash = "sha256-AXT6p5lgF0M9ckoxiAvT1HaJhUWVtwEOadY4otdeB0Q=";
#   };
# 
#   # buildPhase = ''
#   #   runHook preBuild
#   #   yarn --offline build
#   #   runHook postBuild
#   # '';
# 
#   # doDist = false;
# }
# mkYarnModules rec {
#   version = "6.36.0";
#   pname = "signal-desktop-from-src-modules";
#   packageJSON = ./package.json;
#   yarnLock = ./yarn.lock;
#   yarnNix = ./yarn.nix;
# }

stdenv.mkDerivation rec {
  pname = "signal-desktop-from-src";
  version = "6.36.0";
  src = fetchFromGitHub {
    owner = "signalapp";
    repo = "Signal-Desktop";
    rev = "v${version}";
    hash = "sha256-86x6OeQAMN5vhLaAphnAfSWeRgUh0wAeZFzxue8otDQ=";
  };

  nativeBuildInputs = [
    fixup_yarn_lock
    makeWrapper
    nodejs
    python3
    yarn
    # nodejs-slim
  ];
  buildInputs = [
    electron
  ];

  env.yarnOfflineCache = (callPackage ./yarn.nix {}).offline_cache;
  env.ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  configurePhase = ''
    export HOME=$NIX_BUILD_TOP
    yarn config --offline set yarn-offline-mirror $yarnOfflineCache
    fixup_yarn_lock yarn.lock
    # optional flags:  --no-progress --non-interactive
    # yarn install creates the node_modules/ directory
    yarn install --offline --frozen-lockfile --ignore-scripts --ignore-engines
    patchShebangs node_modules/
  '';

  # excerpts from package.json:
  # - "build": "run-s --print-label generate build:esbuild:prod build:release"
  #   - "generate": "npm-run-all build-protobuf build:esbuild sass get-expire-time copy-components"
  #     - "build-protobuf": "yarn build-module-protobuf"
  #       - "build-module-protobuf": "pbjs --target static-module --force-long --no-typeurl --no-verify --no-create --wrap commonjs --out ts/protobuf/compiled.js protos/*.proto && pbts --out ts/protobuf/compiled.d.ts ts/protobuf/compiled.js"
  #     - "build:esbuild": "node scripts/esbuild.js"
  #     - "sass": "sass stylesheets/manifest.scss:stylesheets/manifest.css stylesheets/manifest_bridge.scss:stylesheets/manifest_bridge.css"`
  #     - "get-expire-time": "node ts/scripts/get-expire-time.js"
  #     - "copy-components": "node ts/scripts/copy.js"
  #   - "build:esbuild:prod": "node scripts/esbuild.js --prod"
  #   - "build:release": "cross-env SIGNAL_ENV=production yarn build:electron -- --config.directories.output=release"
  #     - "build:electron": "electron-builder --config.extraMetadata.environment=$SIGNAL_ENV"
  #
  # - "build:dev": "run-s --print-label generate build:esbuild:prod"
  #
  # arch just calls `yarn generate; yarn build`.
  #
  # alpine is much more involved, to reuse their dependencies instead of duplicating stuff.
  # - manually build signal's webrtc using ninja
  # - manually build signal's ringrtc using yarn
  # - manually build libsignal with yarn, cargo and cbindgen
  # - yarn build:acknowledgments
  # - yarn patch-package
  # - npm rebuild esbuild  # apparently esbuild is to be used later in the build process
  # - yarn build:dev
  # - yarn install
  # - then it `mv`s and `patch`s a bunch of stuff
  # - tasje pack
  #
  # for the electron parts, it calls npm with --nodedir=/usr/lib/electron/node_headers
  # - yarn electron-builder doesn't understand --nodedir

  buildPhase = ''
    runHook preBuild
    echo 'ignore-engines true' > .yarnrc

    mkdir -p "$HOME/.node-gyp/${nodejs.version}"
    echo 9 > "$HOME/.node-gyp/${nodejs.version}/installVersion"
    ln -sfv "${nodejs}/include" "$HOME/.node-gyp/${nodejs.version}"
    export npm_config_nodedir=${nodejs}

    # yarn build --offline --frozen-lockfile --ignore-scripts --ignore-engines
    # yarn generate:
    yarn build-module-protobuf --offline --frozen-lockfile --ignore-scripts --ignore-engines
    yarn build:esbuild --offline --frozen-lockfile --ignore-scripts --ignore-engines
    yarn sass
    yarn get-expire-time
    yarn copy-components

    yarn build:esbuild:prod --offline --frozen-lockfile --ignore-scripts --ignore-engines
    # yarn build:release --offline --frozen-lockfile --ignore-scripts --ignore-engines
    # yarn build:release

    echo "build:electron: invocation 1"
    SIGNAL_ENV=production yarn build:electron \
      --dir \
      -c.electronDist=${electron}/libexec/electron \
      -c.electronVersion=${electron.version} || true

    # chmod 777 /build/source/dist/linux-unpacked/signal-desktop

    # echo "build:electron: invocation 2"
    # SIGNAL_ENV=production yarn build:electron \
    #   --dir
    #   -c.electronDist=${electron}/libexec/electron \
    #   -c.electronVersion=${electron.version}
    # SIGNAL_ENV=production yarn --offline --frozen-lockfile --ignore-scripts --ignore-engines electron-builder \
    #   --dir ${if stdenv.isDarwin then "--macos" else "--linux"} ${if stdenv.hostPlatform.isAarch64 then "--arm64" else "--x64"} \
    #   --config.directories.output=release \
    #   --config.extraMetadata.environment=production \
    #   -c.electronDist=${electron}/libexec/electron \
    #   -c.electronVersion=${electron.version}
    # SIGNAL_ENV=production electron-builder \
    #   --dir ${if stdenv.isDarwin then "--macos" else "--linux"} ${if stdenv.hostPlatform.isAarch64 then "--arm64" else "--x64"} \
    #   --config.directories.output=release \
    #   --config.extraMetadata.environment=production \
    #   -c.electronDist=${electron}/libexec/electron \
    #   -c.electronVersion=${electron.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # directory structure follows the original `signal-desktop` nix package
    mkdir -p $out/lib/Signal
    cp -R dist/linux-unpacked/resources $out/lib/Signal/resources
    cp -R dist/linux-unpacked/locales $out/lib/Signal/locales

    makeWrapper ${electron}/bin/electron $out/bin/signal-desktop \
      --add-flags $out/lib/Signal/resources/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --inherit-argv0

    runHook postInstall
  '';

  meta = {
    description = "Private, simple, and secure messenger";
    longDescription = ''
      Signal Desktop is an Electron application that links with your
      "Signal Android" or "Signal iOS" app.
    '';
    homepage = "https://signal.org/";
    changelog = "https://github.com/signalapp/Signal-Desktop/releases/tag/v${version}";
    license = lib.licenses.agpl3Only;
  };
}
