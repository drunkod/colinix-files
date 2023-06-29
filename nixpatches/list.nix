{ fetchpatch2, fetchurl }:
let
  fetchpatch' = {
    saneCommit ? null,
    prUrl ? null,
    hash ? null,
    title ? null,
  }:
    let
      url = if prUrl != null then
        # prUrl takes precedence over any specific commit
        "${prUrl}.diff"
      else
        "https://git.uninsane.org/colin/nixpkgs/commit/${saneCommit}.diff"
      ;
    in fetchpatch2 (
      { inherit url; }
      // (if hash != null then { inherit hash; } else {})
      // (if title != null then { name = title; } else {})
    );
in [

  # (fetchpatch' {
  #   # XXX: doesn't cleanly apply; fetch `firefox-pmos-mobile` branch from my git instead
  #   title = "firefox-pmos-mobile: init at -pmos-2.2.0";
  #   prUrl = "https://github.com/NixOS/nixpkgs/pull/121356";
  #   hash = "sha256-eDsR1cJC/IMmhJl5wERpTB1VGawcnMw/gck9sI64GtQ=";
  # })

  # (fetchpatch' {
  #   saneCommit = "70c12451b783d6310ab90229728d63e8a903c8cb";
  #   title = "firefox-pmos-mobile: init at -pmos-2.2.0";
  #   hash = "sha256-mA22g3ZIERVctq8Uk5nuEsS1JprxA+3DvukJMDTOyso=";
  # })
  # (fetchpatch' {
  #   saneCommit = "ee19a28aa188bb87df836a4edc7b73355b8766eb";
  #   title = "firefox-pmos-mobile: format the generated policies.nix file";
  #   hash = "sha256-K8b3QpyVEjajilB5w4F1UHGDRGlmN7i66lP7SwLZpWI=";
  # })
  # (fetchpatch' {
  #   saneCommit = "c068439c701c160ba15b6ed5abe9cf09b159d584";
  #   title = "firefox-pmos-mobile: implement an updateScript";
  #   hash = "sha256-afiGDHbZIVR3kJuWABox2dakyiRb/8EgDr39esqwcEk=";
  # })
  # (fetchpatch' {
  #   saneCommit = "865c9849a9f7bd048e066c2efd8068ecddd48e33";
  #   title = "firefox-pmos-mobile: 2.2.0 -> 4.0.2";
  #   hash = "sha256-WjWSW0qE+cypvUkDRfK7d9Te8m5zQXwF33z8nEhbvrE=";
  # })
  # (fetchpatch' {
  #   saneCommit = "eb6aae632c55ce7b0a76bca549c09da5e1f7761b";
  #   title = "firefox-pmos-mobile: refactor and populate `passthru` to aid external consumers";
  #   hash = "sha256-/LhbwXjC8vuKzIuGQ3/FGplbLllsz57nR5y+PeDjGuA=";
  # })
  # (fetchpatch' {
  #   saneCommit = "c9b90ef1e17ea21ac779a86994e5d9079a2057b9";
  #   title = "librewolf-pmos-mobile: init";
  #   hash = "sha256-oQEM3EZfAOmfZzDu9faCqyOFZsdHYGn1mVBgkxt68Zg=";
  # })
  (fetchpatch' {
    saneCommit = "c3becd7cdf144d85d12e2e76663e9549a0536efd";
    title = "firefox-pmos-mobile: init at 4.0.2";
    hash = "sha256-NRh2INUMA2K7q8zioqKA7xwoqg7v6sxpuJRpTG5IP1Q=";
  })

  # splatmoji: init at 1.2.0
  (fetchpatch' {
    saneCommit = "75149039b6eaf57d8a92164e90aab20eb5d89196";
    prUrl = "https://github.com/NixOS/nixpkgs/pull/211874";
    hash = "sha256-fftctCx1N/P7yLTRxsHYLHbX+gV/lFpWrWCTtZ2L1Cw=";
  })

  # (fetchpatch {
  #   # stdenv: fix cc for pseudo-crosscompilation
  #   # closed because it breaks pkgsStatic (as of 2023/02/12)
  #   url = "https://github.com/NixOS/nixpkgs/pull/196497.diff";
  #   hash = "sha256-eTwEbVULYjmOW7zUFcTUqvBZqUFjHTKFhvmU2m3XQeo=";
  # })

  ./2022-12-19-i2p-aarch64.patch

  # fix for CMA memory leak in mesa: <https://gitlab.freedesktop.org/mesa/mesa/-/issues/8198>
  # fixed in mesa 22.3.6: <https://gitlab.freedesktop.org/mesa/mesa/-/merge_requests/21330/diffs>
  # only necessary on aarch64.
  # it's a revert of nixpkgs commit dcf630c172df2a9ecaa47c77f868211e61ae8e52
  # ./2023-01-30-mesa-cma-leak.patch
  # upgrade to 22.3.6 instead
  # ./2023-02-28-mesa-22.3.6.patch

  # fix qt6.qtbase and qt6.qtModule to cross-compile.
  # unfortunately there's some tangle that makes that difficult to do via the normal `override` facilities
  ./2023-03-03-qtbase-cross-compile.patch

  # let ccache cross-compile
  # TODO: why doesn't this apply?
  # ./2023-03-04-ccache-cross-fix.patch

  # 2023-04-11: bambu-studio: init at 01.06.02.04
  (fetchpatch' {
    prUrl = "https://github.com/NixOS/nixpkgs/pull/206495";
    hash = "sha256-jl6SZwSDhQTlpM5FyGaFU/svwTb1ySdKtvWMgsneq3A=";
  })

  # (fetchpatch' {
  #   # phoc: 0.25.0 -> 0.27.0
  #   # TODO: move wayland-scanner & glib to nativeBuildInputs
  #   # TODO: once i press power button to screen blank, power doesn't reactivate phoc
  #   # sus commits:
  #   # - all lie between 0.25.0 .. 0.26.0
  #   # - 25d65b9e6ebde26087be6414e41cf516599c3469  2023/03/12 phosh-private: Forward key release as well
  #   # idle inhibit 2023/03/14
  #   #   - 20e7b26af16e9d9c22cba4550f922b90b80b6df6
  #   #   - b081ef963154c7c94a6ab33376a712b3efe17545
  #   # screen blank fix  (NOPE: this one is OK)
  #   #   - 37542bb80be8a7746d2ccda0c02048dd92fac7af  2023/03/11
  #   saneCommit = "12e89c9d26b7a1a79f6b8b2f11fce0dd8f4d5197";
  #   hash = "sha256-IJNBVr2xAwQW4SAJvq4XQYW4D5tevvd9zRrgXYmm38g=";
  # })
  # (fetchpatch' {
  #   # phosh: 0.25.1 -> 0.27.0
  #   # TODO: fix Calls:
  #   # > Failed to get emergency contacts: GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name org.gnome.Calls was not provided by any .service files
  #   saneCommit = "c8fa213c7cb357c0ca0d5bea66278362a47caeb8";
  #   hash = "sha256-I8IZ8fjJstmcIXEN622/A1w2uHDACwXFl1WbXTWOyi4=";
  # })

  # (fetchpatch' {
  #   # phosh-mobile-settings: 0.23.1 -> 0.27.0
  #   # branch: pr/sane/phosh-mobile-settings-0.27.0
  #   # TODO: fix feedback section
  #   # > Settings schema 'org.gtk.gtk4.Settings.FileChooser' is not installed
  #   # ^ is that provided by nautilus?
  #   saneCommit = "8952f79699d3b0d72d9f6efb022e826175b143a6";
  #   hash = "sha256-myKKMt5cZhC0mfPhEsNjwKjaIYICj5LBJqV01HghYUg=";
  # })

  # 2023-04-20: perl: fix modules for compatibility with miniperl
  # (fetchpatch {
  #   url = "https://github.com/NixOS/nixpkgs/pull/225640.diff";
  #   hash = "sha256-MNG8C0OgdPnFQ8SF2loiEhXJuP2z4n9pkXr8Zh4X7QU=";
  # })

  (fetchpatch' {
    title = "conky: 1.13.1 -> 1.18.0";
    prUrl = "https://github.com/NixOS/nixpkgs/pull/217224";
    hash = "sha256-+g3XhmBt/udhbBDiVyfWnfXKvZTvDurlvPblQ9HYp3s=";
  })

  # (fetchpatch' {
  #   title = "hare-json: init at unstable-2023-01-31";
  #   saneCommit = "260f9c6ac4e3564acbceb46aa4b65fbb652f8e23";
  #   hash = "sha256-bjLKANo0+zaxugJlEk1ObPqRHWOKptD7dXB+/xzsYqA=";
  # })
  # (fetchpatch' {
  #   title = "hare-ev: init at unstable-2022-12-29";
  #   saneCommit = "4058200a407c86c5d963bc49b608aa1a881cbbf2";
  #   hash = "sha256-wm1aavbCfxBhcOXh4EhFO4u0LrA9tNr0mSczHUK8mQU=";
  # })
  # (fetchpatch' {
  #   title = "bonsai: init at 1.0.0";
  #   saneCommit = "65d37294d939384e8db400ea82d25ce8b4ad6897";
  #   hash = "sha256-2easgOtJfzvVcz/3nt3lo1GKLLotrM4CkBRyTgIAhHU=";
  # })
  (fetchpatch' {
    title = "bonsai: init at 1.0.0";
    prUrl = "https://github.com/NixOS/nixpkgs/pull/233892";
    hash = "sha256-9XKPNg7TewicfbMgiASpYysTs5aduIVP+4onz+noc/0=";
  })

  # make alsa-project members overridable
  ./2023-05-31-toplevel-alsa.patch

  # qt6 qtwebengine: specify `python` as buildPackages
  ./2023-06-02-qt6-qtwebengine-cross.patch

  # Jellyfin: don't build via `libsForQt5.callPackage`
  ./2023-06-06-jellyfin-no-libsForQt5-callPackage.patch

  # pin to a pre-0.17.3 release
  # removing this and using stock 0.17.3 (also 0.17.4) causes:
  #   INFO lemmy_server::code_migrations: No Local Site found, creating it.
  #   Error: LemmyError { message: None, inner: duplicate key value violates unique constraint "local_site_site_id_key", context: "SpanTrace" }
  # more specifically, lemmy can't find the site because it receives an error from diesel:
  #   Err(DeserializationError("Unrecognized enum variant"))
  # this is likely some mis-ordered db migrations
  # or perhaps the whole set of migrations here isn't being running right.
  # related: <https://github.com/NixOS/nixpkgs/issues/236890#issuecomment-1585030861>
  # ./2023-06-10-lemmy-downgrade.patch

  # (fetchpatch' {
  #   title = "gpodder: wrap with missing `xdg-utils` path";
  #   saneCommit = "10d0ac11bc083cbcf0d6340950079b3888095abf";
  #   hash = "sha256-cu8L30ZiUJnWFGRR/SK917TC7TalzpGkurGkUAAxl54=";
  # })

  (fetchpatch' {
    title = "koreader: 2023.04 -> 2023.05.1";
    saneCommit = "a5c471bd263abe93e291239e0078ac4255a94262";
    hash = "sha256-m++Vv/FK7cxONCz6n0MLO3CiKNrRH0ttFmoC1Xmba+A=";
  })

  (fetchpatch' {
    title = "mepo: 1.1 -> 1.1.2";
    saneCommit = "eee68d7146a6cd985481cdd8bca52ffb204de423";
    hash = "sha256-uNerTwyFzivTU+o9bEKmNMFceOmy2AKONfKJWI5qkzo=";
  })

  (fetchpatch' {
    title = "spdlog: use fmt 9";
    prUrl = "https://github.com/NixOS/nixpkgs/pull/240270";
    hash = "sha256-f0QCnrtPN7XwWk0cHSUW7/XlWPFu6XnuoQL6vARYILM=";
  })

  (fetchpatch' {
    title = "nmap: lua5_3 -> lua5_4";
    prUrl = "https://github.com/NixOS/nixpkgs/pull/240440";
    saneCommit = "a2a5c711e7c0ff43143fc58ec08853ec063f35b3";
    hash = "sha256-YZycbNJfRFD/8bpnS/28ac1x1wWkEhjB3QaGBGAJkUM=";
  })

  # (fetchpatch' {
  #   # N.B.: compiles, but runtime error on launch suggestive of some module not being shipped
  #   title = "matrix-appservice-irc: 0.38.0 -> 1.0.0";
  #   saneCommit = "b168bf862d53535151b9142a15fbd53e18e688c5";
  #   hash = "sha256-dDa2mrCJ416PIYsDH9ya/4aQdqtp4BwzIisa8HdVFxo=";
  # })

  # for raspberry pi: allow building u-boot for rpi 4{,00}
  # TODO: remove after upstreamed: https://github.com/NixOS/nixpkgs/pull/176018
  #   (it's a dupe of https://github.com/NixOS/nixpkgs/pull/112677 )
  ./02-rpi4-uboot.patch

  # ./07-duplicity-rich-url.patch
]
