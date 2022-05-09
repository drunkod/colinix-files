{ lib, beamPackages
, fetchFromGitHub, fetchFromGitLab
, file, cmake, bash
, nixosTests, writeText
, cookieFile ? "/var/lib/pleroma/.cookie"
, ...
}:

beamPackages.mixRelease rec {
  pname = "pleroma";
  version = "2.4.52";

  src = fetchFromGitLab {
    domain = "git.pleroma.social";
    owner = "pleroma";
    repo = "pleroma";
    rev = "4605efe272016a5ba8ba6e96a9bec9a6e40c1591";
    # to update: uncomment the null hash, run nixos-rebuild and
    # compute the new hash with `nix to-sri sha256:<output from failed nix build>`
    # sha256 = "sha256-0000000000000000000000000000000000000000000=";
    sha256 = "sha256-Dp1kTUDfNC7EDoK9WToXkUvsj7v66eKuD15le5IZgiY=";
  };

  preFixup = if (cookieFile != null) then ''
    # There's no way to use a subprocess to cat the content of the
    # file cookie using wrapProgram: it gets escaped (by design) with
    # a pair of backticks :(
    # We have to come up with our own custom wrapper to do this.
    function wrapWithCookie () {
        local hidden
        hidden="$(dirname "$1")/.$(basename "$1")"-wrapped
        while [ -e "$hidden" ]; do
            hidden="''${hidden}_"
        done
        mv "$1" "''${hidden}"

        cat > "$1" << EOF
    #!${bash}/bin/bash
    export RELEASE_COOKIE="\$(cat "${cookieFile}")"
    exec -a "\$0" "''${hidden}" "\$@"
    EOF
        chmod +x "$1"
    }

    for f in "$out"/bin/*; do
        if [[ -x "$f" ]]; then
            wrapWithCookie "$f"
        fi
    done
  '' else "";

  mixNixDeps = import ./mix.nix {
    inherit beamPackages lib;
    overrides = (final: prev: {
      # mix2nix does not support git dependencies yet,
      # so we need to add them manually. these are grabbed from git/pleroma/`mix.exs`
      gettext = beamPackages.buildMix rec {
        name = "gettext";
        version = "0.19.1";

        src = fetchFromGitHub {
          owner = "tusooa";
          repo = "gettext";
          rev = "72fb2496b6c5280ed911bdc3756890e7f38a4808";
          sha256 = "V0qmE+LcAbVoWsJmWE4fwrduYFIZ5BzK/sGzgLY3eH0=";
        };
        beamDeps = with final; [ ];
      };
      crypt = beamPackages.buildRebar3 rec {
        name = "crypt";
        version = "0.4.3";

        src = fetchFromGitHub {
          owner = "msantos";
          repo = "crypt";
          rev = "f75cd55325e33cbea198fb41fe41871392f8fb76";
          sha256 = "sha256-ZYhZTe7cTITkl8DZ4z2IOlxTX5gnbJImu/lVJ2ZjR1o=";
        };

        postInstall = "mv $out/lib/erlang/lib/crypt-${version}/priv/{source,crypt}.so";

        beamDeps = with final; [ elixir_make ];
      };
      prometheus_ex = beamPackages.buildMix rec {
        name = "prometheus_ex";
        version = "3.0.5";

        src = fetchFromGitLab {
          domain = "git.pleroma.social";
          group = "pleroma";
          owner = "elixir-libraries";
          repo = "prometheus.ex";
          rev = "a4e9beb3c1c479d14b352fd9d6dd7b1f6d7deee5";
          sha256 = "1v0q4bi7sb253i8q016l7gwlv5562wk5zy3l2sa446csvsacnpjk";
        };
        beamDeps = with final; [ prometheus ];
      };
      prometheus_phx = beamPackages.buildMix rec {
        name = "prometheus_phx";
        version = "0.1.1";

        preBuild = ''
          touch config/prod.exs
       '';
        src = fetchFromGitLab {
          domain = "git.pleroma.social";
          group = "pleroma";
          owner = "elixir-libraries";
          repo = "prometheus-phx";
          rev = "9cd8f248c9381ffedc799905050abce194a97514";
          sha256 = "0211z4bxb0bc0zcrhnph9kbbvvi1f2v95madpr96pqzr60y21cam";
        };
        beamDeps = with final; [ prometheus_ex ];
      };
      remote_ip = beamPackages.buildMix rec {
        name = "remote_ip";
        version = "0.1.5";

        src = fetchFromGitLab {
          domain = "git.pleroma.social";
          group = "pleroma";
          owner = "elixir-libraries";
          repo = "remote_ip";
          rev = "b647d0deecaa3acb140854fe4bda5b7e1dc6d1c8";
          sha256 = "0c7vmakcxlcs3j040018i7bfd6z0yq6fjfig02g5fgakx398s0x6";
        };
        beamDeps = with final; [ combine plug inet_cidr ];
      };
      captcha = beamPackages.buildMix rec {
        name = "captcha";
        version = "0.1.0";

        src = fetchFromGitLab {
          domain = "git.pleroma.social";
          group = "pleroma";
          owner = "elixir-libraries";
          repo = "elixir-captcha";
          rev = "e0f16822d578866e186a0974d65ad58cddc1e2ab";
          sha256 = "0qbf86l59kmpf1nd82v4141ba9ba75xwmnqzpgbm23fa1hh8pi9c";
        };
        beamDeps = with final; [ ];
      };

      # majic needs a patch to build
      majic = beamPackages.buildMix rec {
        name = "majic";
        version = "1.0.0";

        src = beamPackages.fetchHex {
          pkg = "${name}";
          version = "${version}";
          sha256 = "17hab8kmqc6gsiqicfgsaik0rvmakb6mbshlbxllj3b5fs7qa1br";
        };

        # src = fetchFromGitLab {
        #   domain = "git.pleroma.social";
        #   group = "pleroma";
        #   owner = "elixir-libraries";
        #   repo = "majic";
        #   rev = "289cda1b6d0d70ccb2ba508a2b0bd24638db2880";
        #   sha256 = "15605lsdd74bmsp5z96f76ihn7m2g3p1hjbhs2x7v7309n1k108n";
        # };
        # patchPhase = ''
        #   substituteInPlace lib/majic/server.ex --replace "erlang.now" "erlang.time"
        # '';
        buildInputs = [ file ];

        beamDeps = with final; [ nimble_pool mime plug elixir_make ];
      };


      # Some additional build inputs and build fixes
      http_signatures = prev.http_signatures.override {
        patchPhase = ''
          substituteInPlace mix.exs --replace ":logger" ":logger, :public_key"
        '';
      };
      fast_html = prev.fast_html.override {
        nativeBuildInputs = [ cmake ];
        dontUseCmakeConfigure = true;
      };
      syslog = prev.syslog.override {
        buildPlugins = with beamPackages; [ pc ];
      };

      # This needs a different version (1.0.14 -> 1.0.18) to build properly with
      # our Erlang/OTP version.
      eimp = beamPackages.buildRebar3 rec {
        name = "eimp";
        version = "1.0.18";

        src = beamPackages.fetchHex {
          pkg = name;
          inherit version;
          sha256 = "0fnx2pm1n2m0zs2skivv43s42hrgpq9i143p9mngw9f3swjqpxvx";
        };

        patchPhase = ''
          echo '{plugins, [pc]}.' >> rebar.config
        '';
        buildPlugins = with beamPackages; [ pc ];

        beamDeps = with final; [ p1_utils ];
      };

      mime = prev.mime.override {
        patchPhase = let
          cfgFile = writeText "config.exs" ''
            use Mix.Config
            config :mime, :types, %{
              "application/activity+json" => ["activity+json"],
              "application/jrd+json" => ["jrd+json"],
              "application/ld+json" => ["activity+json"],
              "application/xml" => ["xml"],
              "application/xrd+xml" => ["xrd+xml"]
            }
          '';
        in ''
          mkdir config
          cp ${cfgFile} config/config.exs
        '';
      };
    });
  };

  passthru = {
    tests.pleroma = nixosTests.pleroma;
    inherit mixNixDeps;
  };

  meta = with lib; {
    description = "ActivityPub microblogging server";
    homepage = "https://git.pleroma.social/pleroma/pleroma";
    license = licenses.agpl3;
    maintainers = with maintainers; [ petabyteboy ninjatrappeur yuka kloenk ];
    platforms = platforms.unix;
  };
}
