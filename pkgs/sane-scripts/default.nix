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
        coreutils
        curl
        file
        findutils
        gnugrep
        gocryptfs
        ifuse
        inotify-tools
        ncurses
        oath-toolkit
        openssh
        rmlint
        rsync
        ssh-to-age
        sops
        sudo
        util-linux
        which
      ];
      keep = {
        # we write here: keep it
        "/tmp/rmlint.sh" = true;
        # intentionally escapes (into user code)
        "$external_cmd" = true;
      };
      fake = {
        external = [
          # https://github.com/abathur/resholve/issues/29
          "umount"
          "sudo"

          # these are used internally; probably a better fix
          "sane-mount-servo"
          "sane-private-unlock"
        ];
      };

      # list of programs which *can* or *cannot* exec their arguments
      execer = with pkgs; [
        "cannot:${gocryptfs}/bin/gocryptfs"
        "cannot:${ifuse}/bin/ifuse"
        "cannot:${oath-toolkit}/bin/oathtool"
        "cannot:${openssh}/bin/ssh-keygen"
        "cannot:${rmlint}/bin/rmlint"
        "cannot:${rsync}/bin/rsync"
        "cannot:${sops}/bin/sops"
        "cannot:${ssh-to-age}/bin/ssh-to-age"
      ];
    };
  };

  installPhase = ''
    mkdir -p "$out/bin"
    cp -R * "$out"/bin/
  '';

  meta = {
    description = "collection of scripts associated with uninsane systems";
    homepage = "https://git.uninsane.org";
    platforms = lib.platforms.all;
  };
}
