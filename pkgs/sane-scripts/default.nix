{ lib
, pkgs
, resholve
}:

# resholve documentation:
# - nix: https://github.com/nixos/nixpkgs/blob/master/pkgs/development/misc/resholve/README.md
# - generic: https://github.com/abathur/resholve
resholve.mkDerivation {
  pname = "sane-scripts";
  version = "0.1.0";

  src = ./src;

  solutions = {
    default = {
      # note: `scripts` refers to the store path here
      scripts = [ "bin/*" ];
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = with pkgs; [
        # string is interpreted as relative path from @OUT@.
        # this lets our scripts reference eachother.
        # see: <https://github.com/abathur/resholve/issues/26>
        "bin"
        coreutils-full
        curl
        duplicity
        file
        findutils
        gnugrep
        gnused
        gocryptfs
        ifuse
        inetutils
        inotify-tools
        iwd
        jq
        ncurses
        oath-toolkit
        openssh
        openssl
        rmlint
        rsync
        ssh-to-age
        sops
        sudo
        systemd
        util-linux
        which
      ];
      keep = {
        "/run/secrets/duplicity_passphrase" = true;
        # we write here: keep it
        "/tmp/rmlint.sh" = true;
        # intentionally escapes (into user code)
        "$external_cmd" = true;
        "$maybe_sudo" = true;
      };
      fake = {
        external = [
          # https://github.com/abathur/resholve/issues/29
          # "umount"
          # "/run/wrappers/bin/sudo"
          "sudo"
        ];
      };
      fix = {
        # this replaces umount with the non-setuid-wrapper umount.
        # not sure if/where that lack of suid causes problems.
        umount = true;
      };
      # prologue is broken; see <https://github.com/abathur/resholve/issues/89>
      # prologue = "bin/prologue";

      # list of programs which *can* or *cannot* exec their arguments
      execer = with pkgs; [
        "cannot:${duplicity}/bin/duplicity"
        "cannot:${gocryptfs}/bin/gocryptfs"
        "cannot:${ifuse}/bin/ifuse"
        "cannot:${iwd}/bin/iwctl"
        "cannot:${oath-toolkit}/bin/oathtool"
        "cannot:${openssh}/bin/ssh-keygen"
        "cannot:${rmlint}/bin/rmlint"
        "cannot:${rsync}/bin/rsync"
        "cannot:${sops}/bin/sops"
        "cannot:${ssh-to-age}/bin/ssh-to-age"
        "cannot:${systemd}/bin/systemctl"
      ];
    };
  };

  patchPhase = ''
    # remove python scripts
    # TODO: figure out how to make resholve process only shell scripts
    rm sane-reclaim-boot-space
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp -R * $out/bin/
    # allow scripts to make use of sudo, umount wrappers
    sed -i '3iPATH=$PATH:/run/wrappers/bin' $out/bin/*;
  '';

  meta = {
    description = "collection of scripts associated with uninsane systems";
    homepage = "https://git.uninsane.org";
    platforms = lib.platforms.all;
  };
}
