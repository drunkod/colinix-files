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
      scripts = [ "bin/*" ];
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = with pkgs; [
        coreutils
        curl
        findutils
        gnugrep
        ifuse
        inotifyTools
        oath-toolkit
        openssh
        rmlint
        rsync
        ssh-to-age
        sops
        sudo
        which
      ];
      keep = {
        # we write here: keep it
        "/tmp/rmlint.sh" = true;
      };
      fake = {
        external = [
          # https://github.com/abathur/resholve/issues/29
          "umount"
          "sudo"

          # this is actually internal; probably a better fix
          "sane-mount-servo"
        ];
      };

      # list of programs which *can* or *cannot* exec their arguments
      execer = [
        "cannot:${pkgs.ifuse}/bin/ifuse"
        "cannot:${pkgs.oath-toolkit}/bin/oathtool"
        "cannot:${pkgs.openssh}/bin/ssh-keygen"
        "cannot:${pkgs.rmlint}/bin/rmlint"
        "cannot:${pkgs.rsync}/bin/rsync"
        "cannot:${pkgs.ssh-to-age}/bin/ssh-to-age"
        "cannot:${pkgs.sops}/bin/sops"
      ];
    };
  };

  installPhase = ''
    mkdir -p "$out"
    cp -R * "$out"/
  '';

  meta = {
    description = "collection of scripts associated with uninsane systems";
    homepage = "https://git.uninsane.org";
    platforms = lib.platforms.all;
  };
}
