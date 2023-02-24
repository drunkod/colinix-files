# cross compiling

# - for edge-casey things, see in nixpkgs:
#   - `git show da9a9a440415b236f22f57ba67a24ab3fb53f595`
#     - e.g. `mesonEmulatorHook`, `depsBuildBuild`, `python3.pythonForBuild`
#   - <doc/stdenv/cross-compilation.chapter.md>
#     - e.g. `makeFlags = [ "CC=${stdenv.cc.targetPrefix}cc" ];`
#
# build a particular package as evaluated here with:
# - toplevel: `nix build '.#host-pkgs.moby-cross.xdg-utils'`
# - scoped:   `nix build '.#host-pkgs.moby-cross.gnome.mutter'`
# - python:   `nix build '.#host-pkgs.moby-cross.python310Packages.pandas'`
# - perl:     `nix build '.#host-pkgs.moby-cross.perl536Packages.ModuleBuild'`
# - qt:       `nix build '.#host-pkgs.moby-cross.qt5.qtbase'`
# - qt:       `nix build '.#host-pkgs.moby-cross.libsForQt5.phonon'`
# most of these can be built in a nixpkgs source root like:
# - `nix build '.#pkgsCross.aarch64-multiplatform.xdg-utils'`
# - `nix build '.#pkgsCross.gnu64.xdg-utils'`  # for x86_64-linux
#
# tracking issues, PRs:
# - libuv tests fail: <https://github.com/NixOS/nixpkgs/issues/190807>
#   - last checked: 2023-02-07
#   - opened: 2022-09-11
# - perl Module Build broken: <https://github.com/NixOS/nixpkgs/issues/66741>
#   - last checked: 2023-02-07
#   - opened: 2019-08
#   - ModuleBuild needs access to `Scalar/Utils.pm`, which doesn't *seem* to exist in the cross builds
#     - this can be fixed by adding `nativeBuildInputs = [ perl ]` to it
#     - alternatively, there's some "stubbing" method mentioned in <pkgs/development/interpreters/perl/default.nix>
#       - stubbing documented at bottom: <nixpkgs:doc/languages-frameworks/perl.section.md>
#
# - perl536Packages.Testutf8 fails to cross: <https://github.com/NixOS/nixpkgs/issues/198548>
#   - last checked: 2023-02-07
#   - opened: 2022-10
# - python310Packages.psycopg2: <https://github.com/NixOS/nixpkgs/issues/210265>
#   - last checked: 2023-02-06
#   - i have a potential fix:
#     """
#       i was able to just add `postgresql` to the `buildInputs`  (so that it's in both `buildInputs` and `nativeBuildInputs`):
#       it fixed the build for `pkgsCross.aarch64-multiplatform.python310Packages.psycopg2` but not for `armv7l-hf-multiplatform` that this issue description calls out.
#
#       also i haven't deployed it yet to make sure this doesn't cause anything funky at runtime though.
#     """

# TODO:
# - ??.llvmPackages_14.llvm: "FAIL: LLVM-Unit :: ExecutionEngine/MCJIT/./MCJITTests/MCJITMultipleModuleTest.two_module_global_variables_case (43769 of 46988)"
#   - nix log /nix/store/ib2yw6sajnhlmibxkrn7lj7chllbr85h-llvm-14.0.6.drv
#   - wanted by clang-11-12-LLVMgold-path, compiler-rt-libc-12.0.1, clang-wrapper-12.0.1
# - ?..llvmPackages_12.llvm: "FAIL: LLVM-Unit :: ExecutionEngine/MCJIT/./MCJITTests/MCJITTest.return_global (2857 of 42084)"
#   - nix log /nix/store/6vydavlxh1gvs0vmrkcx9qp67g3h7kcz-llvm-12.0.1.drv
#   - wanted by sequoia, rav1e, rustc-1.66.1
# - `host-pkgs.desko.stdenv` fails build:
#   - #cross-compiling:nixos.org says pkgsCross.gnu64 IS KNOWN TO NOT COMPILE. let this go for now:
#     - make a `<machine>` (don't specifiy local/targetSystem) and `<machine>-cross` target.
#     - `desko-cross` will be broken but `desko` can work
#   - see <nixpkgs:pkgs/stdenv/linux/default.nix>
#   - disallowedRequisites = [ bootstrapTools.out ];
#   """
#   error: output '/nix/store/w2vgzyvs2jzf7yr6qqqrjbvrqxxmhwy0-stdenv-linux' is not allowed to refer to the following paths:
#            /nix/store/2qbgchkjj1hqi1c8raznwml94pkm3k7q-libunistring-1.0
#            /nix/store/4j425ybkjxcdj89352l5gpdl3nmxq4zn-libidn2-2.3.2
#            /nix/store/c35hf8g5b9vksadym9dbjrd6p2y11m8h-glibc-2.35-224
#            /nix/store/qbgfsaviwqi2p6jr7an1g2754sv3xqhn-gcc-11.3.0-lib
#   """
#   - rg doesn't reveal any such references in the output though...
#     - nor references to bootstrapTools
#     - HOWEVER, IT DOES CONTAIN A REFERENCE TO THE PREVIOUS STAGE'S BASH:
#       - /nix/store/w2vgzyvs2jzf7yr6qqqrjbvrqxxmhwy0-stdenv-linux/setup
#       - export SHELL=/nix/store/qqa28hmysc23yy081d178jfd9a1yk8aw-bash-5.2-p15/bin/bash
#       - not clear if that matters? but maybe it reaches bootstrapTools transitively?
#         - yeah: that bash specifies the above `glibc` as its loader
#         - so we probably can't `inherit` the emulated bash like that.
#   - try building `.#host-pkgs.desko.stdenv.shellPackage` or `.#host-pkgs.desko.stdenv.bootstrapTools`
#   - `file result/bin/bash` does show that it uses the interpreter for the glibc, above


{ config, lib, pkgs, ... }:

let
  # these are the overlays which we *also* pass through to the cross and emulated package sets.
  # TODO: refactor to not specify same overlay in multiple places (here and flake.nix).
  overlays = [
    (import ./../../overlays/pkgs.nix)
    (import ./../../overlays/pins.nix)
  ];
  mkCrossFrom = localSystem: pkgs:
    import pkgs.path {
      inherit localSystem;  # localSystem is equivalent to buildPlatform
      crossSystem = pkgs.stdenv.hostPlatform.system;
      inherit (config.nixpkgs) config;
      inherit overlays;
    };
  mkEmulated = pkgs:
    import pkgs.path {
      # system = pkgs.stdenv.hostPlatform.system;
      localSystem = pkgs.stdenv.hostPlatform.system;
      inherit (config.nixpkgs) config;
      inherit overlays;
    };
in
{
  # options = {
  #   perlPackageOverrides = lib.mkOption {
  #   };
  # };

  config = {
    # the configuration of which specific package set `pkgs.cross` refers to happens elsewhere;
    # here we just define them all.

    nixpkgs.config.perlPackageOverrides = pkgs: (with pkgs; with pkgs.perlPackages; {
      # these are the upstream nixpkgs perl modules, but with `nativeBuildInputs = [ perl ]`
      # to fix cross compilation errors
      ModuleBuild = buildPerlPackage {
        pname = "Module-Build";
        version = "0.4231";
        src = fetchurl {
          url = "mirror://cpan/authors/id/L/LE/LEONT/Module-Build-0.4231.tar.gz";
          hash = "sha256-fg9MaSwXQMGshOoU1+o9i8eYsvsmwJh3Ip4E9DCytxc=";
        };
        # support cross-compilation by removing unnecessary File::Temp version check
        # postPatch = lib.optionalString (stdenv.hostPlatform != stdenv.buildPlatform) ''
        #   sed -i '/File::Temp/d' Build.PL
        # '';
        nativeBuildInputs = [ perl ];
        meta = {
          description = "Build and install Perl modules";
          license = with lib.licenses; [ artistic1 gpl1Plus ];
          mainProgram = "config_data";
        };
      };
      FileBaseDir = buildPerlModule {
        version = "0.08";
        pname = "File-BaseDir";
        src = fetchurl {
          url = "mirror://cpan/authors/id/K/KI/KIMRYAN/File-BaseDir-0.08.tar.gz";
          hash = "sha256-wGX80+LyKudpk3vMlxuR+AKU1QCfrBQL+6g799NTBeM=";
        };
        configurePhase = ''
          runHook preConfigure
          perl Build.PL PREFIX="$out" prefix="$out"
        '';
        nativeBuildInputs = [ perl ];
        propagatedBuildInputs = [ IPCSystemSimple ];
        buildInputs = [ FileWhich ];
        meta = {
          description = "Use the Freedesktop.org base directory specification";
          license = with lib.licenses; [ artistic1 gpl1Plus ];
        };
      };
      # fixes: "FAILED IPython/terminal/tests/test_debug_magic.py::test_debug_magic_passes_through_generators - pexpect.exceptions.TIMEOUT: Timeout exceeded."
      Testutf8 = buildPerlPackage {
        pname = "Test-utf8";
        version = "1.02";
        src = fetchurl {
          url = "mirror://cpan/authors/id/M/MA/MARKF/Test-utf8-1.02.tar.gz";
          hash = "sha256-34LwnFlAgwslpJ8cgWL6JNNx5gKIDt742aTUv9Zri9c=";
        };
        nativeBuildInputs = [ perl ];
        meta = {
          description = "Handy utf8 tests";
          homepage = "https://github.com/2shortplanks/Test-utf8/tree";
          license = with lib.licenses; [ artistic1 gpl1Plus ];
        };
      };
      # inherit (pkgs.emulated.perl.pkgs)
      #   Testutf8
      # ;
    });
    nixpkgs.overlays = [
      (next: prev: {
        # non-emulated packages build *from* local *for* target.
        # for large packages like the linux kernel which are expensive to build under emulation,
        # the config can explicitly pull such packages from `pkgs.cross` to do more efficient cross-compilation.
        # crossFrom."x86_64-linux" = mkCrossFrom "x86_64-linux" prev;
        # crossFrom."aarch64-linux" = mkCrossFrom "aarch64-linux" prev;

        emulated = mkEmulated prev;
      })
      # (next: prev:
      #   let
      #     emulated = prev.emulated;
      #   in {
      #     # packages which don't "cross compile" from x86_64 -> x86_64
      #     inherit (emulated)
      #       # aws-crt-cpp  # "/build/source/include/aws/crt/Optional.h:6:10: fatal error: utility: No such file or directory"
      #       # # bash  # "configure: error: C compiler cannot create executables"
      #       # boehmgc  # "gc_badalc.cc:29:10: fatal error: new: No such file or directory <new>"
      #       # c-ares  # dns-proto.h:11:10: fatal error: memory: No such file or directory
      #       # db48  # "./db_cxx.h:59:10: fatal error: iostream.h: No such file or directory"
      #       # # kexec-tools  # "configure: error: C compiler cannot create executables"
      #       # gmp6  # "configure: error: could not find a working compiler"
      #       # gtest  # "/build/source/googletest/src/gtest_main.cc:30:10: fatal error: cstdio: No such file or directory"
      #       # icu72  # "../common/unicode/localpointer.h:45:10: fatal error: memory: No such file or directory"
      #       # # libidn2  # "configure: error: C compiler cannot create executables"
      #       # ncurses  # "configure: error: C compiler cannot create executables"
      #     ;

      #     bash = prev.bash.overrideAttrs (orig: {
      #       # configure doesn't know how to build because it doesn't know where to find crt1.o.
      #       # some parts of nixpkgs specify the path to it explicitly:
      #       # - <nixpkgs:pkgs/development/libraries/gcc/libstdc++/5.nix>
      #       # - <nixpkgs:pkgs/build-support/cc-wrapper/add-flags.sh>
      #       # alternatively, the wrapper gcc (first item on PATH if we look at a failed bash's env-vars)
      #       # adds these flags automatically. so we can probably just tell `configure` to *not* use any special gcc other than the wrapper.
      #       # TESTING IN PROGRESS:
      #       # - N.B.: BUILDCC is a vlc-ism!
      #       # BUILDCC = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}cc";  # has illegal requisites
      #       CC = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}cc";  # XXX: tested in nixpkgs: FAILS WITH SAME SIGNATURE. env-vars doesn't show our CC though :-(
      #       # ^ env vars set here are making their way through, but something else (build script?) is overwriting it
      #       SANE_CC = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}cc";
      #       # CC = "gcc"  # bash configure.ac
      #       # CC_FOR_BUILD = "gcc"  # bash configure.ac
      #       # BUILDCC = "gcc";  # VLC
      #     });
      #   }
      # )
      (nativeSelf: nativeSuper: {
        pkgsi686Linux = nativeSuper.pkgsi686Linux.extend (i686Self: i686Super: {
          # fixes eval-time error: "Unsupported cross architecture"
          #   it happens even on a x86_64 -> x86_64 build:
          #   - defining `config.nixpkgs.buildPlatform` to the non-default causes that setting to be inherited by pkgsi686.
          #   - hence, `pkgsi686` on a non-cross build is ordinarily *emulated*:
          #     defining a cross build causes it to also be cross (but to the right hostPlatform)
          # this has no inputs other than stdenv, and fetchurl, so emulating it is fine.
          tbb = nativeSuper.emulated.pkgsi686Linux.tbb;
          # tbb = i686Super.tbb.overrideAttrs (orig: (with i686Self; {
          #   makeFlags = lib.optionals stdenv.cc.isClang [
          #     "compiler=clang"
          #   ] ++ (lib.optional (stdenv.buildPlatform != stdenv.hostPlatform)
          #     (if stdenv.hostPlatform.isAarch64 then "arch=arm64"
          #     else if stdenv.hostPlatform.isx86_64 then "arch=intel64"
          #     else throw "Unsupported cross architecture: ${stdenv.buildPlatform.system} -> ${stdenv.hostPlatform.system}"));
          # }));
        });
      })
      (next: prev:
        let
          emulated = prev.emulated;
          # emulated = if prev.stdenv.buildPlatform.system == prev.stdenv.hostPlatform.system then
          #   prev
          # else
          #   prev.emulated;
        in {
          # packages which don't cross compile
          inherit (emulated)
            # adwaita-qt  # psqlodbc
            apacheHttpd_2_4  # `configure: error: Size of "void *" is less than size of "long"`
            # duplicity  # python3.10-s3transfer
            fwupd-efi  # efi/meson.build:162:0: ERROR: Program or command 'gcc' not found or not executable
            # gdk-pixbuf  # cross-compiled version doesn't output bin/gdk-pixbuf-thumbnailer  (used by webp-pixbuf-loader
            gmime3  # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
            # gnome-tour
            # XXX: gnustep members aren't individually overridable, because the "scope" uses `rec` such that members don't see overrides
            gnustep  # gnustep.base: "configure: error: Your compiler does not appear to implement the -fconstant-string-class option needed for support of strings."
            # grpc
            # nixpkgs hdf5 is at commit 3e847e003632bdd5fdc189ccbffe25ad2661e16f
            # hdf5  # configure: error: cannot run test program while cross compiling
            # http2
            ibus  # configure.ac:152: error: possibly undefined macro: AM_PATH_GLIB_2_0
            kitty  # "FileNotFoundError: [Errno 2] No such file or directory: 'pkg-config'"
            libgccjit  # "../../gcc-9.5.0/gcc/jit/jit-result.c:52:3: error: 'dlclose' was not declared in this scope"
            # libsForQt5  # qtbase  # make: g++: No such file or directory
            libtiger  # "src/tiger_internal.h:24:10: fatal error: pango/pango.h: No such file or directory"
            notmuch  # "Error: The dependencies of notmuch could not be satisfied"  (xapian, gmime, glib, talloc)
            # perlInterpreters  # perl5.36.0-Module-Build perl5.36.0-Test-utf8 (see tracking issues ^)
            phosh  # libadwaita-1 not found
            # qgnomeplatform
            # qtbase
            qt5  # qt5.qtx11extras fails, but we can't selectively emulate it
            qt6  # "You need to set QT_HOST_PATH to cross compile Qt."
            sequoia  # "/nix/store/q8hg17w47f9xr014g36rdc2gi8fv02qc-clang-aarch64-unknown-linux-gnu-12.0.1-lib/lib/libclang.so.12: cannot open shared object file: No such file or directory"', /build/sequoia-0.27.0-vendor.tar.gz/bindgen/src/lib.rs:1975:31"
            # splatmoji
            squeekboard  # meson.build:1:0: ERROR: 'rust' compiler binary not defined in cross or native file
            twitter-color-emoji  # /nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 1: pkg-config: command not found
            visidata  # python3.10-psycopg2 python3.10-pandas python3.10-h5py
            # webkitgtk_4_1  # requires nativeBuildInputs = perl.pkgs.FileCopyRecursive => perl5.36.0-Test-utf8
            # xdg-utils  # perl5.36.0-File-BaseDir / perl5.36.0-Module-Build
          ;

          # apacheHttpd_2_4 = prev.apacheHttpd_2_4.override {
          #   # fixes original error
          #   # new failure mode: "/nix/store/czvaa9y9ch56z53c0b0f5bsjlgh14ra6-apr-aarch64-unknown-linux-gnu-1.7.0-dev/share/build/libtool: line 1890: aarch64-unknown-linux-gnu-ar: command not found"
          #   inherit (emulated) stdenv;
          # };

          # mod_dnssd = prev.mod_dnssd.override {
          #   inherit (emulated) stdenv;
          # };
          apacheHttpdPackagesFor = apacheHttpd: self:
            let
              prevHttpdPkgs = prev.apacheHttpdPackagesFor apacheHttpd self;
            in prevHttpdPkgs // {
              # fixes "configure: error: *** Sorry, could not find apxs ***"
              mod_dnssd = prevHttpdPkgs.mod_dnssd.override {
                inherit (emulated) stdenv;
              };
            };
          # apacheHttpdPackagesFor = apacheHttpd: self:
          #   let
          #     prevHttpdPkgs = lib.fix (emulated.apacheHttpdPackagesFor apacheHttpd);
          #   in
          #     (prev.apacheHttpdPackagesFor apacheHttpd self) // {
          #       # inherit (prevHttpdPkgs) mod_dnssd;
          #       mod_dnssd = prevHttpdPkgs.mod_dnssd.override {
          #         inherit (self) apacheHttpd;
          #       };
          #     };
          # appstream = prev.appstream.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          # appstream = prev.appstream.overrideAttrs (orig: {
          #   # fixes "Program 'gperf' not found or not executable"
          #   # does not fix "ERROR: An exe_wrapper is needed but was not found. Please define one in cross file and check the command and/or add it to PATH."
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gperf ];
          # });
          # appstream = prev.appstream.overrideAttrs (upstream: {
          #   # does not fix "Program 'gperf' not found or not executable"
          #   nativeBuildInputs = upstream.nativeBuildInputs ++ lib.optionals (!prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) [
          #     next.mesonEmulatorHook
          #   ];
          # });
          appstream = prev.appstream.overrideAttrs (upstream: {
            # fixes "Program 'gperf' not found or not executable"
            nativeBuildInputs = upstream.nativeBuildInputs ++ lib.optionals (!prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) [
              next.mesonEmulatorHook
            ] ++ [
              next.gperf
            ];
          });

          blueman = prev.blueman.overrideAttrs (orig: {
            # configure: error: ifconfig or ip not found, install net-tools or iproute2
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.iproute2 ];
          });
          brltty = prev.brltty.override {
            # configure: error: no acceptable C compiler found in $PATH
            inherit (emulated) stdenv;
          };
          browserpass = prev.browserpass.override {
            # fixes "qemu-aarch64: Could not open '/lib/ld-linux-aarch64.so.1': No such file or directory"
            inherit (emulated) buildGoModule;  # buildGoModule holds the stdenv
          };
          cantarell-fonts = prev.cantarell-fonts.override {
            # fixes error where python3.10-skia-pathops dependency isn't available for the build platform
            inherit (emulated) stdenv;
          };
          cdrtools = prev.cdrtools.override {
            # "configure: error: installation or configuration problem: C compiler cc not found."
            inherit (emulated) stdenv;
          };

          # colord = prev.colord.override {
          #   # doesn't fix: "ld: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          colord = prev.colord.overrideAttrs (upstream: {
            # fixes: (meson) ERROR: An exe_wrapper is needed but was not found. Please define one in cross file and check the command and/or add it to PATH.
            nativeBuildInputs = upstream.nativeBuildInputs ++ lib.optionals (!prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) [
              next.mesonEmulatorHook
            ];
          });

          dante = prev.dante.override {
            # fixes: "configure: error: error: getaddrinfo() error value count too low"
            inherit (emulated) stdenv;
          };

          emacs = prev.emacs.override {
            # fixes "configure: error: cannot run test program while cross compiling"
            inherit (emulated) stdenv;
          };

          flatpak = prev.flatpak.overrideAttrs (upstream: {
            # fixes "No package 'libxml-2.0' found"
            buildInputs = upstream.buildInputs ++ [ next.libxml2 ];
            configureFlags = upstream.configureFlags ++ [
              "--enable-selinux-module=no"  # fixes "checking for /usr/share/selinux/devel/Makefile... configure: error: cannot check for file existence when cross compiling"
              "--disable-gtk-doc"  # fixes "You must have gtk-doc >= 1.20 installed to build documentation for Flatpak"
            ];
          });

          fuzzel = prev.fuzzel.overrideAttrs (upstream: {
            # fixes: "meson.build:100:0: ERROR: Dependency lookup for wayland-scanner with method 'pkgconfig' failed: Pkg-config binary for machine 0 not found. Giving up."
            depsBuildBuild = upstream.depsBuildBuild or [] ++ [ next.pkg-config ];
          });

          # fwupd-efi = prev.fwupd-efi.override {
          #   # efi/meson.build:33:2: ERROR: Problem encountered: gnu-efi support requested, but headers were not found
          #   inherit (emulated) stdenv;
          # };
          fwupd = prev.fwupd.overrideAttrs (orig: {
            # solves (meson) "Run-time dependency libgcab-1.0 found: NO (tried pkgconfig and cmake)", and others.
            buildInputs = orig.buildInputs ++ [ next.gcab next.gnutls ];
            mesonFlags = (lib.remove "-Ddocs=enabled" orig.mesonFlags) ++ [ "-Ddocs=disabled" ];
            outputs = lib.remove "devdoc" orig.outputs;
          });
          # fwupd = prev.fwupd.override {
          #   # solves missing libgcab-1.0;
          #   # new error: "meson.build:449:4: ERROR: Command "/nix/store/n7xrj3pnrgcr8igx7lfhz8197y67bk7k-python3-aarch64-unknown-linux-gnu-3.10.9-env/bin/python3 po/test-deps" failed with status 1."
          #   inherit (emulated) stdenv;
          # };

          gcr_4 = prev.gcr_4.overrideAttrs (orig: {
            # fixes (meson): "ERROR: Program 'gpg2 gpg' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gnupg next.openssh ];
          });
          gthumb = prev.gthumb.overrideAttrs (orig: {
            # fixes (meson) "Program 'glib-mkenums mkenums' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          gmime = prev.gmime.overrideAttrs (orig: {
            # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
            configureFlags = orig.configureFlags ++ [ "ac_cv_have_iconv_detect_h=no" ];
          });

          # gmime3 = prev.gmime3.overrideAttrs (orig: {
          #   # "checking preferred charset formats for system iconv... cannot run test program while cross compiling"
          #   # unsolved: "ImportError: /nix/store/c190src4bjkfp7bdgc5sadnmvgzv7kxb-gobject-introspection-aarch64-unknown-linux-gnu-1.74.0/lib/gobject-introspection/giscanner/_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
          #   configureFlags = orig.configureFlags ++ [ "ac_cv_have_iconv_detect_h=no" ];
          # });
          # gmime3 = prev.gmime3.override {
          #   # doesn't fix
          #   inherit (emulated) stdenv;
          # };

          gnome = prev.gnome.overrideScope' (self: super: {
            inherit (emulated.gnome)
              dconf-editor  # "error: Package `dconf' not found in specified Vala API directories or GObject-Introspection GIR directories"
              evolution-data-server  # "The 'perl' not found, not installing csv2vcard"
              gnome-shell  # "meson.build:128:0: ERROR: Program 'gjs' not found or not executable"
            ;
            # dconf-editor = super.dconf-editor.override {
            #   # fails to fix original error
            #   inherit (emulated) stdenv;
            # };
            # dconf-editor = super.dconf-editor.overrideAttrs (orig: {
            #   # fails to fix original error
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.dconf ];
            # });
            evince = super.evince.overrideAttrs (orig: {
              # fixes (meson) "Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)"
              # inspired by gupnp
              outputs = [ "out" "dev" ]
                ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
              mesonFlags = orig.mesonFlags ++ [
                "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
              ];
            });
            # evolution-data-server = super.evolution-data-server.override {
            #   inherit (next) stdenv;
            # };
            # evolution-data-server = super.evolution-data-server.overrideAttrs (orig: {
            #   # fixes "The 'perl' not found, not installing csv2vcard"
            #   # doesn't fix "CMake Error: try_run() invoked in cross-compiling mode, please set the following cache variables appropriately"
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
            # });
            # file-roller = super.file-roller.override {
            #   # fixes "src/meson.build:106:0: ERROR: Program 'glib-compile-resources' not found or not executable"
            #   inherit (emulated) stdenv;
            # };
            file-roller = super.file-roller.overrideAttrs (orig: {
              # fixes: "src/meson.build:106:0: ERROR: Program 'glib-compile-resources' not found or not executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            gnome-color-manager = super.gnome-color-manager.overrideAttrs (orig: {
              # fixes: "src/meson.build:3:0: ERROR: Program 'glib-compile-resources' not found or not executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            gnome-control-center = super.gnome-control-center.overrideAttrs (orig: {
              # fixes "subprojects/gvc/meson.build:30:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # gnome-control-center = super.gnome-control-center.override {
            #   inherit (next) stdenv;
            # };
            # gnome-keyring = super.gnome-keyring.override {
            #   # does not fix original error
            #   inherit (next) stdenv;
            # };
            gnome-keyring = super.gnome-keyring.overrideAttrs (orig: {
              # fixes "configure.ac:374: error: possibly undefined macro: AM_PATH_LIBGCRYPT"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libgcrypt next.openssh next.glib ];
            });
            gnome-remote-desktop = super.gnome-remote-desktop.overrideAttrs (orig: {
              # TODO: remove gnome-remote-desktop (wanted by gnome-control-center)
              # fixes: "Program gdbus-codegen found: NO"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # gnome-shell = super.gnome-shell.overrideAttrs (orig: {
            #   # fixes "meson.build:128:0: ERROR: Program 'gjs' not found or not executable"
            #   # does not fix "_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"  (python import failure)
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gjs next.gobject-introspection ];
            #   # try to reduce gobject-introspection/shew dependencies
            #   mesonFlags = [
            #     "-Dextensions_app=false"
            #     "-Dextensions_tool=false"
            #     "-Dman=false"
            #   ];
            #   # fixes "gvc| Build-time dependency gobject-introspection-1.0 found: NO"
            #   # inspired by gupnp_1_6
            #   # outputs = [ "out" "dev" ]
            #   #   ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            #   # mesonFlags = [
            #   #   "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            #   # ];
            # });
            # gnome-shell = super.gnome-shell.override {
            #   inherit (next) stdenv;
            # };
            # gnome-shell = super.gnome-shell.overrideAttrs (orig: {
            #   # does not solve original error
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.mesonEmulatorHook ];
            # });
            # gnome-settings-daemon = super.gnome-settings-daemon.overrideAttrs (orig: {
            #   # does not fix original error
            #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.mesonEmulatorHook ];
            # });
            gnome-settings-daemon = super.gnome-settings-daemon.overrideAttrs (orig: {
              # glib solves: "Program 'glib-mkenums mkenums' not found or not executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
              # pkg-config solves: "plugins/power/meson.build:22:0: ERROR: Dependency lookup for glib-2.0 with method 'pkgconfig' failed: Pkg-config binary for machine 0 not found."
              # stdenv.cc fixes: "plugins/power/meson.build:60:0: ERROR: No build machine compiler for 'plugins/power/gsd-power-enums-update.c'"
              # but then it fails with a link-time error.
              # depsBuildBuild = orig.depsBuildBuild or [] ++ [ next.glib next.pkg-config next.buildPackages.stdenv.cc ];
              # hack to just not build the power plugin (panel?), to avoid cross compilation errors
              postPatch = orig.postPatch + ''
                sed -i "s/disabled_plugins = \[\]/disabled_plugins = ['power']/" plugins/meson.build
              '';
            });
            gnome-session = super.gnome-session.overrideAttrs (orig: {
              # fixes: "gdbus-codegen not found or executable"
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            # gnome-terminal = super.gnome-terminal.override {
            #   # fixes: "meson.build:343:0: ERROR: Dependency "libpcre2-8" not found, tried pkgconfig"
            #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libglib-2.0.so: error adding symbols: file in wrong format"
            #   inherit (emulated) stdenv;
            # };
            gnome-terminal = super.gnome-terminal.overrideAttrs (orig: {
              # fixes "meson.build:343:0: ERROR: Dependency "libpcre2-8" not found, tried pkgconfig"
              buildInputs = orig.buildInputs ++ [ next.pcre2 ];
            });
            gnome-user-share = super.gnome-user-share.overrideAttrs (orig: {
              # fixes: meson.build:111:6: ERROR: Program 'glib-compile-schemas' not found or not executable
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
            });
            mutter = super.mutter.overrideAttrs (orig: {
              # buildInputs += [next.mesa] fixes "meson.build:237:2: ERROR: Dependency "gbm" not found, tried pkgconfig"
              # buildInputs += [next.glib] fixes "clutter/clutter/meson.build:281:0: ERROR: Program 'glib-mkenums mkenums' not found or not executable"
              # introspection=false and remove docs=true fixes gobject-introspection/_giscanner import error
              nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib next.wayland-scanner ];
              buildInputs = orig.buildInputs ++ [ next.mesa ];
              mesonFlags = (lib.remove "-Ddocs=true" orig.mesonFlags)
                ++ [ "-Dintrospection=false" ];
              outputs = lib.remove "devdoc" orig.outputs;
            });
            # nautilus = super.nautilus.override {
            #   # fixes: "meson.build:123:0: ERROR: Dependency "libxml-2.0" not found, tried pkgconfig"
            #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libglib-2.0.so: error adding symbols: file in wrong format"
            #   inherit (emulated) stdenv;
            # };
            nautilus = super.nautilus.overrideAttrs (orig: {
              # fixes: "meson.build:123:0: ERROR: Dependency "libxml-2.0" not found, tried pkgconfig"
              buildInputs = orig.buildInputs ++ [ next.libxml2 ];
            });
          });

          gocryptfs = prev.gocryptfs.override {
            # fixes "error: hash mismatch in fixed-output derivation" (vendorSha256)
            inherit (emulated) buildGoModule;  # equivalent to stdenv
          };
          gupnp_1_6 = prev.gupnp_1_6.overrideAttrs (orig: {
            # fixes "subprojects/gi-docgen/meson.build:10:0: ERROR: python3 not found"
            # this patch is copied from the default gupnp.
            # TODO: upstream
            outputs = [ "out" "dev" ]
              ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            mesonFlags = [
              "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
              "-Dintrospection=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            ];
          });

          gst_all_1 = prev.gst_all_1 // {
            # gst-editing-services = prev.gst_all_1.gst-editing-services.override {
            #   # fixes "Run-time dependency gst-validate-1.0 found: NO"
            #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/f7yr5z123d162p5457jh3wzkqm7x8yah-glib-2.74.3/lib/libgobject-2.0.so: error adding symbols: file in wrong format"
            #   inherit (emulated) stdenv;
            # };
            # XXX this feels risky; it propagates a (conflicting) gst-plugins to all consumers
            # gst-editing-services = emulated.gst_all_1.gst-editing-services;
            gst-editing-services = prev.gst_all_1.gst-editing-services.overrideAttrs (orig: {
              # fixes "Run-time dependency gst-validate-1.0 found: NO"
              buildInputs = orig.buildInputs ++ [ next.gst_all_1.gst-devtools ];
              mesonFlags = orig.mesonFlags ++ [
                # disable "python formatters" to avoid undefined references to Py_Initialize, etc.
                "-Dpython=disabled"
              ];
            });
            inherit (emulated.gst_all_1) gst-plugins-good;
            # gst-plugins-good = prev.gst_all_1.gst-plugins-good.override {
            #   # when invoked with `qt5Support = true`, qtbase shows up in both buildInputs and nativeBuildInputs
            #   # if these aren't identical, then qt complains: "Error: detected mismatched Qt dependencies"
            #   # doesn't fix the original error.
            #   inherit (emulated) stdenv;
            #   # qt5Support = true;
            # };
          };
          gvfs = prev.gvfs.overrideAttrs (upstream: {
            nativeBuildInputs = upstream.nativeBuildInputs ++ [
              next.openssh
              next.glib  # fixes "gdbus-codegen: command not found"
            ];
            # fixes "meson.build:312:2: ERROR: Assert failed: http required but libxml-2.0 not found"
            buildInputs = upstream.buildInputs ++ [ next.libxml2 ];
          });

          # hdf5 = prev.hdf5.override {
          #   inherit (emulated) stdenv;
          # };

          # ibus = prev.ibus.override {
          #   # "_giscanner.cpython-310-x86_64-linux-gnu.so: cannot open shared object file: No such file or directory"
          #   inherit (emulated) stdenv;
          # };

          iio-sensor-proxy = prev.iio-sensor-proxy.overrideAttrs (orig: {
            # fixes "./autogen.sh: line 26: gtkdocize: not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib next.gtk-doc ];
          });

          # kitty = prev.kitty.override {
          #   # does not solve original error
          #   inherit (emulated) stdenv;
          # };

          libchamplain = prev.libchamplain.overrideAttrs (upstream: {
            # fixes: "failed to produce output path for output 'devdoc'"
            outputs = lib.remove "devdoc" upstream.outputs;
          });
          libgweather = prev.libgweather.overrideAttrs (upstream: {
            # fixes: "Run-time dependency vapigen found: NO (tried pkgconfig)"
            mesonFlags =
              (
                lib.remove "-Denable_vala=true"
                  (lib.remove "-Dgtk_doc=true" upstream.mesonFlags)
              ) ++ [
                "-Dintrospection=false"
                "-Denable_vala=false"
                "-Dgtk_doc=false"
              ];
            outputs = lib.remove "devdoc" upstream.outputs;
            nativeBuildInputs = (lib.remove next.gobject-introspection upstream.nativeBuildInputs) ++ [
              next.glib
            ];
          });
          libHX = prev.libHX.overrideAttrs (orig: {
            # "Can't exec "libtoolize": No such file or directory at /nix/store/r4fvx9hazsm0rdm7s393zd5v665dsh1c-autoconf-2.71/share/autoconf/Autom4te/FileUtils.pm line 294."
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libtool ];
          });
          libjcat = prev.libjcat.overrideAttrs (upstream: {
            # fixes: "ERROR: Program 'gnutls-certtool certtool' not found or not executable"
            # N.B.: gnutls library is used by the compiled program (i.e. the host);
            #   gnutls binaries are used by the build machine.
            #   therefore gnutls can be specified in both buildInputs and nativeBuildInputs
            nativeBuildInputs = upstream.nativeBuildInputs ++ [ next.gnutls ];
            # buildInputs = lib.remove next.gnutls upstream.buildInputs;
          });

          librest = prev.librest.overrideAttrs (orig: {
            # fixes "You must have gtk-doc >= 1.13 installed to build documentation"
            #   by removing the "--enable-gtk-doc" flag
            configureFlags = [ "--with-ca-certificates=/etc/ssl/certs/ca-certificates.crt" ];
          });
          librest_1_0 = prev.librest_1_0.overrideAttrs (orig: {
            # fixes (meson) "Run-time dependency gi-docgen found: NO (tried pkgconfig and cmake)"
            # inspired by gupnp
            outputs = [ "out" "dev" ]
              ++ lib.optionals (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform) [ "devdoc" ];
            mesonFlags = orig.mesonFlags ++ [
              "-Dgtk_doc=${lib.boolToString (prev.stdenv.buildPlatform == prev.stdenv.hostPlatform)}"
            ];
          });
          libsForQt5 = prev.libsForQt5.overrideScope' (self: super: {
            qgpgme = super.qgpgme.overrideAttrs (orig: {
              # fix so it can find the MOC compiler
              # it looks like it might not *need* to propagate qtbase, but so far unclear
              nativeBuildInputs = orig.nativeBuildInputs ++ [ self.qtbase ];
              propagatedBuildInputs = lib.remove self.qtbase orig.propagatedBuildInputs;
            });
            phonon = super.phonon.overrideAttrs (orig: {
              # fixes "ECM (required version >= 5.60), Extra CMake Modules"
              buildInputs = orig.buildInputs ++ [ next.extra-cmake-modules ];
            });
          });

          # libtiger = prev.libtiger.override {
          #   # fails to fix: "src/tiger_internal.h:24:10: fatal error: pango/pango.h: No such file or directory"
          #   inherit (emulated) stdenv;
          # };
          # libtiger = prev.libtiger.overrideAttrs (orig: {
          #   # fails to fix: "src/tiger_internal.h:24:10: fatal error: pango/pango.h: No such file or directory"
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.libkate next.cairo next.pango ];
          # });

          libvisual = prev.libvisual.overrideAttrs (upstream: {
            # fixes: "configure: error: *** sdl-config not found."
            # 2023/02/21: TODO: update nixpkgs to remove this override.
            # - it's fixed by 11b095e8805aa123a4d77a5e706bebaf86622879
            buildInputs = [ next.glib ];
            configureFlags = [ "--disable-examples" ];
          });

          ncftp = prev.ncftp.overrideAttrs (upstream: {
            # fixes: "ar: command not found"
            # `ar` is provided by bintools
            nativeBuildInputs = upstream.nativeBuildInputs or [] ++ [ next.bintools ];
          });
          networkmanager-fortisslvpn = prev.networkmanager-fortisslvpn.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          # networkmanager-iodine = prev.networkmanager-iodine.overrideAttrs (orig: {
          #   # fails to fix "configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT"
          #   nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gettext ];
          # });
          networkmanager-iodine = prev.networkmanager-iodine.override {
            # fixes "configure.ac:58: error: possibly undefined macro: AM_GLIB_GNU_GETTEXT"
            inherit (emulated) stdenv;
          };
          networkmanager-l2tp = prev.networkmanager-l2tp.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            # fixes "gtk4-builder-tool: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib next.gtk4 ];
          });
          networkmanager-openconnect = prev.networkmanager-openconnect.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          networkmanager-openvpn = prev.networkmanager-openvpn.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          networkmanager-sstp = prev.networkmanager-sstp.overrideAttrs (orig: {
            # fixes "gdbus-codegen: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          networkmanager-vpnc = prev.networkmanager-vpnc.overrideAttrs (orig: {
            # fixes "properties/gresource.xml: Permission denied"
            #   - by providing glib-compile-resources
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          nheko = prev.nheko.overrideAttrs (orig: {
            # fixes "fatal error: lmdb++.h: No such file or directory
            buildInputs = orig.buildInputs ++ [ next.lmdbxx ];
          });
          # notmuch = prev.notmuch.override {
          #   # fails to solve original error
          #   inherit (emulated) stdenv;
          # };
          obex_data_server = prev.obex_data_server.override {
            # fixes "/nix/store/0wk6nr1mryvylf5g5frckjam7g7p9gpi-bash-5.2-p15/bin/bash: line 2: --prefix=ods_manager: command not found"
            inherit (emulated) stdenv;
          };
          openfortivpn = prev.openfortivpn.override {
            # fixes "checking for /proc/net/route... configure: error: cannot check for file existence when cross compiling"
            inherit (emulated) stdenv;
          };
          ostree = prev.ostree.override {
            # fixes "configure: error: Need GPGME_PTHREAD version 1.1.8 or later"
            inherit (emulated) stdenv;
          };
          pam_mount = prev.pam_mount.overrideAttrs (orig: {
            # fixes: "perl: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
          });

          phoc = prev.phoc.override {
            # fixes "Program wayland-scanner found: NO"
            inherit (emulated) stdenv;
          };
          # phosh = prev.phosh.override {
          #   # fixes original error.
          #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/2bzd39fbsifidd667s7x930d0b7pm3qx-pango-1.50.12/lib/libpangocairo-1.0.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          phosh-mobile-settings = prev.phosh-mobile-settings.override {
            # fixes "meson.build:26:0: ERROR: Dependency "phosh-plugins" not found, tried pkgconfig"
            inherit (emulated) stdenv;
          };
          pipewire = prev.pipewire.overrideAttrs (orig: {
            # fix `spa/plugins/bluez5/meson.build:41:0: ERROR: Program 'gdbus-codegen' not found or not executable`
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          psqlodbc = prev.psqlodbc.override {
            # fixes "configure: error: odbc_config not found (required for unixODBC build)"
            inherit (emulated) stdenv;
          };

          pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
            (py-next: py-prev: {
              defcon = py-prev.defcon.overridePythonAttrs (orig: {
                # TODO: diagnose and upstream
                nativeBuildInputs = orig.nativeBuildInputs ++ orig.nativeCheckInputs;
              });
              executing = py-prev.executing.overridePythonAttrs (orig: {
                # TODO: confirm & upstream
                # test has an assertion that < 1s of CPU time elapsed => flakey
                disabledTestPaths = orig.disabledTestPaths or [] ++ [
                  # "tests/test_main.py::TestStuff::test_many_source_for_filename_calls"
                  "tests/test_main.py"
                ];
              });
              # h5py = py-prev.h5py.overridePythonAttrs (orig: {
              #   # XXX: can't upstream until its dependency, hdf5, is fixed. that looks TRICKY.
              #   # - the `setup_configure.py` in h5py tries to dlopen (and call into) the hdf5 lib to query the version and detect features like MPI
              #   # - it could be patched with ~10 LoC in the HDF5LibWrapper class.
              #   #
              #   # expose numpy and hdf5 as available at build time
              #   nativeBuildInputs = orig.nativeBuildInputs ++ orig.propagatedBuildInputs ++ orig.buildInputs;
              #   buildInputs = [];
              #   # HDF5_DIR = "${hdf5}";
              # });
              ipython = py-prev.ipython.overridePythonAttrs (orig: {
                # fixes "FAILED IPython/terminal/tests/test_debug_magic.py::test_debug_magic_passes_through_generators - pexpect.exceptions.TIMEOUT: Timeout exceeded."
                disabledTests = orig.disabledTests ++ [ "test_debug_magic_passes_through_generator" ];
              });
              mutatormath = py-prev.mutatormath.overridePythonAttrs (orig: {
                # TODO: diagnose and upstream
                nativeBuildInputs = orig.nativeBuildInputs or [] ++ orig.nativeCheckInputs;
              });
              pandas = py-prev.pandas.overridePythonAttrs (orig: {
                # TODO: upstream
                # XXX: we only actually need numpy when building in ~/nixpkgs repo: not sure why we need all the propagatedBuildInputs here.
                # nativeBuildInputs = orig.nativeBuildInputs ++ [ py-next.numpy ];
                nativeBuildInputs = orig.nativeBuildInputs ++ orig.propagatedBuildInputs;
              });
              psycopg2 = py-prev.psycopg2.overridePythonAttrs (orig: {
                # TODO: upstream  (see tracking issue)
                #
                # psycopg2 *links* against libpg, so we need the host postgres available at build time!
                # present-day nixpkgs only includes it in nativeBuildInputs
                buildInputs = orig.buildInputs ++ [ next.postgresql ];
              });
              s3transfer = py-prev.s3transfer.overridePythonAttrs (orig: {
                # tests explicitly expect host CPU == build CPU
                # Bail out! ERROR:../plugins/core.c:221:qemu_plugin_vcpu_init_hook: assertion failed: (success)
                # Bail out! ERROR:../accel/tcg/cpu-exec.c:954:cpu_exec: assertion failed: (cpu == current_cpu)
                disabledTestPaths = orig.disabledTestPaths ++ [
                  # "tests/functional/test_processpool.py::TestProcessPoolDownloader::test_cleans_up_tempfile_on_failure"
                  "tests/functional/test_processpool.py"
                  # "tests/unit/test_compat.py::TestBaseManager::test_can_provide_signal_handler_initializers_to_start"
                  "tests/unit/test_compat.py"
                ];
              });
              # skia-pathops = ?
              #   it tries to call `cc` during the build, but can't find it.
            })
          ];
          # qt5 = prev.qt5.overrideScope' (self: super: {
          #   qtbase = super.qtbase.override {
          #     inherit (emulated) stdenv;
          #   };
          #   qtx11extras = super.qtx11extras.override {
          #     # "Project ERROR: Cannot run compiler 'g++'";
          #     # this fails an assert though, where the cross qt now references the emulated qt.
          #     inherit (emulated.qt5) qtModule;
          #   };
          # });
          # qt6 = prev.qt6.overrideScope' (self: super: {
          #   qtbase = super.qtbase.override {
          #     # fixes: "You need to set QT_HOST_PATH to cross compile Qt."
          #     inherit (emulated) stdenv;
          #   };
          # });
          rapidfuzz-cpp = prev.rapidfuzz-cpp.overrideAttrs (orig: {
            # fixes "error: could not find git for clone of catch2-populate"
            buildInputs = orig.buildInputs or [] ++ [ next.catch2_3 ];
          });
          re2 = (prev.re2.override {
            # fixes: "FAILED: CMakeFiles/test.util"
            inherit (emulated) stdenv;
          }).overrideAttrs (orig: {
            # exhaustive{,1,2}_test times out after 1500s.
            # this is after exhaustive3_test takes 600s to pass.
            doCheck = false;
          });
          rmlint = prev.rmlint.override {
            # fixes "Checking whether the C compiler works... no"
            inherit (emulated) stdenv;
          };
          # sequoia = prev.sequoia.override {
          #   # fails to fix original error
          #   inherit (emulated) stdenv;
          # };

          # squeekboard = prev.squeekboard.overrideAttrs (orig: {
          #   # fixes: "meson.build:1:0: ERROR: 'rust' compiler binary not defined in cross or native file"
          #   # new error: "meson.build:1:0: ERROR: Rust compiler rustc --target aarch64-unknown-linux-gnu -C linker=aarch64-unknown-linux-gnu-gcc can not compile programs."
          #   mesonFlags =
          #     let
          #       # ERROR: 'rust' compiler binary not defined in cross or native file
          #       crossFile = next.writeText "cross-file.conf" ''
          #         [binaries]
          #         rust = [ 'rustc', '--target', '${next.rust.toRustTargetSpec next.stdenv.hostPlatform}' ]
          #       '';
          #     in
          #       orig.mesonFlags or [] ++ lib.optionals (next.stdenv.hostPlatform != next.stdenv.buildPlatform) [ "--cross-file=${crossFile}" ];
          # });
          # squeekboard = prev.squeekboard.override {
          #   # new error: "gcc: error: unrecognized command line option '-m64'"
          #   inherit (emulated) stdenv;
          # };

          sysprof = prev.sysprof.overrideAttrs (orig: {
            # fixes: "src/meson.build:12:2: ERROR: Program 'gdbus-codegen' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          tpm2-abrmd = prev.tpm2-abrmd.overrideAttrs (orig: {
            # fixes "configure: error: *** gdbus-codegen is required to build tpm2-abrmd; No package 'gio-unix-2.0' found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.glib ];
          });
          tracker-miners = prev.tracker-miners.override {
            # fixes "meson.build:183:0: ERROR: Can not run test applications in this cross environment."
            inherit (emulated) stdenv;
          };
          # twitter-color-emoji = prev.twitter-color-emoji.override {
          #   # fails to fix original error
          #   inherit (emulated) stdenv;
          # };

          unar = prev.unar.overrideAttrs (upstream: {
            # fixes: "ar: command not found"
            # `ar` is provided by bintools
            nativeBuildInputs = upstream.nativeBuildInputs ++ [ next.bintools ];
          });
          unixODBCDrivers = prev.unixODBCDrivers // {
            # TODO: should this package be deduped with toplevel psqlodbc in upstream nixpkgs?
            psql = prev.unixODBCDrivers.psql.override {
              # fixes "configure: error: odbc_config not found (required for unixODBC build)"
              inherit (emulated) stdenv;
            };
            # psql = prev.unixODBCDrivers.psql.overrideAttrs (orig: {
            #   # fixes "configure: error: odbc_config not found (required for unixODBC build)"
            #   # new error: "/nix/store/h3ms3h95rbj5p8yhxfhbsbnxgvpnb8w0-aarch64-unknown-linux-gnu-binutils-2.39/bin/aarch64-unknown-linux-gnu-ld: /nix/store/6h6z98qvg5k8rsqpivi42r5008zjfp2v-unixODBC-2.3.11/lib/libodbcinst.so: error adding symbols: file in wrong format"
            #   nativeBuildInputs = orig.nativeBuildInputs or [] ++ orig.buildInputs;
            # });
          };

          vlc = prev.vlc.overrideAttrs (orig: {
            # fixes: "configure: error: could not find the LUA byte compiler"
            # fixes: "configure: error: protoc compiler needed for chromecast was not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.lua5 next.protobuf ];
            # fix that it can't find the c compiler
            # makeFlags = orig.makeFlags or [] ++ [ "CC=${prev.stdenv.cc.targetPrefix}cc" ];
            BUILDCC = "${prev.stdenv.cc}/bin/${prev.stdenv.cc.targetPrefix}cc";
          });
          vpnc = prev.vpnc.overrideAttrs (orig: {
            # fixes "perl: command not found"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.perl ];
          });
          xdg-desktop-portal-gtk = prev.xdg-desktop-portal-gtk.overrideAttrs (orig: {
            # fixes "No package 'xdg-desktop-portal' found"
            buildInputs = orig.buildInputs ++ [ next.xdg-desktop-portal ];
          });
          xdg-desktop-portal-gnome = prev.xdg-desktop-portal-gnome.overrideAttrs (orig: {
            # fixes: "data/meson.build:33:5: ERROR: Program 'msgfmt' not found or not executable"
            # fixes: "src/meson.build:25:0: ERROR: Program 'gdbus-codegen' not found or not executable"
            nativeBuildInputs = orig.nativeBuildInputs ++ [ next.gettext next.glib ];
          });
          # webp-pixbuf-loader = prev.webp-pixbuf-loader.override {
          #   # fixes "Builder called die: Cannot wrap '/nix/store/kpp8qhzdjqgvw73llka5gpnsj0l4jlg8-gdk-pixbuf-aarch64-unknown-linux-gnu-2.42.10/bin/gdk-pixbuf-thumbnailer' because it is not an executable file"
          #   # new failure mode: "/nix/store/grqh2wygy9f9wp5bgvqn4im76v82zmcx-binutils-2.39/bin/ld: /nix/store/2syg6jxk8zi1zkpqvkxkz87x8sl27c6b-gdk-pixbuf-2.42.10/lib/libgdk_pixbuf-2.0.so: error adding symbols: file in wrong format"
          #   inherit (emulated) stdenv;
          # };
          webp-pixbuf-loader = prev.webp-pixbuf-loader.overrideAttrs (upstream: {
            # fixes: "Builder called die: Cannot wrap '/nix/store/kpp8qhzdjqgvw73llka5gpnsj0l4jlg8-gdk-pixbuf-aarch64-unknown-linux-gnu-2.42.10/bin/gdk-pixbuf-thumbnailer' because it is not an executable file"
            # gdk-pixbuf doesn't create a `bin/` directory when cross-compiling, breaks some thumbnailing stuff.
            # see `librsvg` for a more bullet-proof cross-compilation approach
            postInstall = "";
          });
      })
    ];
  };
}
