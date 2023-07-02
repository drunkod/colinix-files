{ lib
, python3Packages
, static-nix-shell
, symlinkJoin
, transmission
}:

let
  sane-lib = {
    # TODO: we could simplify the lib/ folder structure
    # by auto-generating the setup.py files in `postPatch`, below
    bt = python3Packages.buildPythonPackage {
      pname = "sane-lib-bt";
      version = "0.1.0";
      format = "setuptools";
      src = ./src/lib/bt;
      propagatedBuildInputs = [ transmission ];
      pythonImportChecks = [
        "sane_bt"
      ];
    };
    ssdp = python3Packages.buildPythonPackage {
      pname = "sane-lib-ssdp";
      version = "0.1.0";
      format = "setuptools";
      src = ./src/lib/ssdp;
      pythonImportChecks = [
        "sane_ssdp"
      ];
    };
  };

  sane-bin = {
    # anything added to this attrset gets symlink-joined into `sane-scripts`
    # and is made available through `sane-scripts.passthru`
    backup-ls = static-nix-shell.mkBash {
      pname = "sane-backup-ls";
      src = ./src;
      pkgs = [ "duplicity" ];
    };
    backup-restore = static-nix-shell.mkBash {
      pname = "sane-backup-restore";
      src = ./src;
      pkgs = [ "duplicity" ];
    };
    bt-add = static-nix-shell.mkPython3Bin {
      pname = "sane-bt-add";
      src = ./src;
      pyPkgs = [ "sane-lib.bt" ];
      pkgs = [ "sane-scripts.lib.bt.propagatedBuildInputs" ];
    };
    bt-rm = static-nix-shell.mkPython3Bin {
      pname = "sane-bt-rm";
      src = ./src;
      pyPkgs = [ "sane-lib.bt" ];
      pkgs = [ "sane-scripts.lib.bt.propagatedBuildInputs" ];
    };
    bt-search = static-nix-shell.mkPython3Bin {
      pname = "sane-bt-search";
      src = ./src;
      pyPkgs = [ "natsort" "requests" ];
    };
    bt-show = static-nix-shell.mkPython3Bin {
      pname = "sane-bt-show";
      src = ./src;
      pyPkgs = [ "sane-lib.bt" ];
      pkgs = [ "sane-scripts.lib.bt.propagatedBuildInputs" ];
    };
    deadlines = static-nix-shell.mkBash {
      pname = "sane-deadlines";
      src = ./src;
      pkgs = [ "coreutils-full" ];
    };
    dev-cargo-loop = static-nix-shell.mkBash {
      pname = "sane-dev-cargo-loop";
      src = ./src;
      pkgs = [ "inotify-tools" "ncurses" ];
    };
    find-dotfiles = static-nix-shell.mkBash {
      pname = "sane-find-dotfiles";
      src = ./src;
      pkgs = [ "findutils" ];
    };
    git-init = static-nix-shell.mkBash {
      pname = "sane-git-init";
      src = ./src;
      pkgs = [ "git" ];
    };
    ip-check = static-nix-shell.mkBash {
      pname = "sane-ip-check";
      src = ./src;
      pkgs = [ "curl" "gnugrep" ];
    };
    ip-check-upnp = static-nix-shell.mkPython3Bin {
      pname = "sane-ip-check-upnp";
      src = ./src;
      pkgs = [ "miniupnpc" ];
      pyPkgs = [ "sane-lib.ssdp" ];
    };
    ip-port-forward = static-nix-shell.mkPython3Bin {
      pname = "sane-ip-port-forward";
      src = ./src;
      pkgs = [ "inetutils" "miniupnpc" ];
      pyPkgs = [ "sane-lib.ssdp" ];
    };
    ip-reconnect = static-nix-shell.mkPython3Bin {
      pname = "sane-ip-reconnect";
      src = ./src;
    };
    private-change-passwd = static-nix-shell.mkBash {
      pname = "sane-private-change-passwd";
      src = ./src;
      pkgs = [ "gocryptfs" "rsync" "sane-scripts.private-unlock" ];
    };
    private-do = static-nix-shell.mkBash {
      pname = "sane-private-do";
      src = ./src;
      pkgs = [ "sane-scripts.private-unlock" ];
    };
    private-init = static-nix-shell.mkBash {
      pname = "sane-private-init";
      src = ./src;
      pkgs = [ "gocryptfs" ];
    };
    private-lock = static-nix-shell.mkBash {
      pname = "sane-private-lock";
      src = ./src;
    };
    private-unlock = static-nix-shell.mkBash {
      pname = "sane-private-unlock";
      src = ./src;
      pkgs = [ "gocryptfs" ];
    };
    rcp = static-nix-shell.mkBash {
      pname = "sane-rcp";
      src = ./src;
      pkgs = [ "rsync" ];
    };
    reboot = static-nix-shell.mkBash {
      pname = "sane-reboot";
      src = ./src;
      pkgs = [ "systemd" ];
    };
    reclaim-boot-space = static-nix-shell.mkPython3Bin {
      pname = "sane-reclaim-boot-space";
      src = ./src;
    };
    reclaim-disk-space = static-nix-shell.mkBash {
      pname = "sane-reclaim-disk-space";
      src = ./src;
      pkgs = [ "nix" "rmlint" "util-linux" ];
    };
    secrets-dump = static-nix-shell.mkBash {
      pname = "sane-secrets-dump";
      src = ./src;
      pkgs = [ "gnugrep" "sops" "oath-toolkit" ];
    };
    secrets-unlock = static-nix-shell.mkBash {
      pname = "sane-secrets-unlock";
      src = ./src;
      pkgs = [ "coreutils-full" "openssh" "ssh-to-age" ];
    };
    secrets-update-keys = static-nix-shell.mkBash {
      pname = "sane-secrets-update-keys";
      src = ./src;
      pkgs = [ "coreutils-full" "findutils" "sops" ];
    };
    shutdown = static-nix-shell.mkBash {
      pname = "sane-shutdown";
      src = ./src;
      pkgs = [ "inetutils" "systemd" ];
    };
    ssl-dump = static-nix-shell.mkBash {
      pname = "sane-ssl-dump";
      src = ./src;
      pkgs = [ "openssl" ];
    };
    stop-all-servo = static-nix-shell.mkBash {
      pname = "sane-stop-all-servo";
      src = ./src;
      pkgs = [ "systemd" ];
    };
    sudo-redirect = static-nix-shell.mkBash {
      pname = "sane-sudo-redirect";
      src = ./src;
      pkgs = [ "coreutils-full" ];
    };
    sync-from-iphone = static-nix-shell.mkZsh {
      pname = "sane-sync-from-iphone";
      src = ./src;
      pkgs = [ "coreutils-full" "ifuse" "rsync" ];
    };
    sync-from-servo = static-nix-shell.mkBash {
      pname = "sane-sync-from-servo";
      src = ./src;
      pkgs = [ "rsync" ];
    };
    vpn-down = static-nix-shell.mkBash {
      pname = "sane-vpn-down";
      src = ./src;
      pkgs = [ "coreutils-full" "gnugrep" "gnused" "sane-scripts.ip-check" "systemd" ];
    };
    vpn-up = static-nix-shell.mkBash {
      pname = "sane-vpn-up";
      src = ./src;
      pkgs = [ "coreutils-full" "gnugrep" "gnused" "sane-scripts.ip-check" "systemd" ];
    };
    which = static-nix-shell.mkBash {
      pname = "sane-which";
      src = ./src;
      pkgs = [ "coreutils-full" "file" ];
    };
    wipe-browser = static-nix-shell.mkBash {
      pname = "sane-wipe-browser";
      src = ./src;
    };
  };
in
symlinkJoin {
  name = "sane-scripts";
  paths = lib.attrValues sane-bin;
  passthru = sane-bin // {
    lib = sane-lib;
  };
  meta = {
    description = "collection of scripts associated with sane systems";
    homepage = "https://git.uninsane.org";
    platforms = lib.platforms.all;
  };
}
