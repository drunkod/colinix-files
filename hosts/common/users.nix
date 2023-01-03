{ config, pkgs, lib, ... }:

# installer docs: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/profiles/installation-device.nix
with lib;
let
  cfg = config.sane.users;
  # see nixpkgs/nixos/modules/services/networking/dhcpcd.nix
  hasDHCP = config.networking.dhcpcd.enable &&
    (config.networking.useDHCP || any (i: i.useDHCP == true) (attrValues config.networking.interfaces));

in
{
  options = {
    sane.users.guest.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {
    # Users are exactly these specified here;
    # old ones will be deleted (from /etc/passwd, etc) upon upgrade.
    users.mutableUsers = false;

    # docs: https://nixpkgs-manual-sphinx-markedown-example.netlify.app/generated/options-db.xml.html#users-users
    users.users.colin = {
      # sets group to "users" (?)
      isNormalUser = true;
      home = "/home/colin";
      createHome = true;
      homeMode = "700";
      uid = config.sane.allocations.colin-uid;
      # i don't get exactly what this is, but nixos defaults to this non-deterministically
      # in /var/lib/nixos/auto-subuid-map and i don't want that.
      subUidRanges = [
        { startUid=100000; count=1; }
      ];
      group = "users";
      extraGroups = [
        "wheel"
        "nixbuild"
        "networkmanager"
        # phosh/mobile. XXX colin: unsure if necessary
        "video"
        "feedbackd"
        "dialout" # required for modem access
      ];

      # initial password is empty, in case anything goes wrong.
      # if `colin-passwd` (a password hash) is successfully found/decrypted, that becomes the password at boot.
      initialPassword = lib.mkDefault "";
      passwordFile = lib.mkIf (config.sops.secrets ? "colin-passwd") config.sops.secrets.colin-passwd.path;

      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = builtins.attrValues (import ../../modules/pubkeys.nix).users;

      # mount encrypted stuff at login
      # some other nix pam users:
      # - <https://github.com/g00pix/nixconf/blob/32c04f6fa843fed97639dd3f09e157668d3eea1f/profiles/sshfs.nix>
      # - <https://github.com/lourkeur/distro/blob/11173454c6bb50f7ccab28cc2c757dca21446d1d/nixos/profiles/users/louis-full.nix>
      # - <https://github.com/dnr/sample-nix-code/blob/03494480c1fae550c033aa54fd96aeb3827761c5/nixos/laptop.nix>
      pamMount = let
        priv = config.fileSystems."/home/colin/private";
      in {
        fstype = priv.fsType;
        path = priv.device;
        mountpoint = priv.mountPoint;
        options = builtins.concatStringsSep "," priv.options;
      };
    };

    security.pam.mount.enable = true;

    # ensure ~ perms are known to sane.fs module.
    # TODO: this is generic enough to be lifted up into sane.fs itself.
    sane.fs."/home/colin".dir.acl = {
      user = "colin";
      group = config.users.users.colin.group;
      mode = config.users.users.colin.homeMode;
    };

    sane.impermanence.dirs.home.plaintext = [
      "archive"
      "dev"
      # TODO: records should be private
      "records"
      "ref"
      "tmp"
      "use"
      "Music"
      "Pictures"
      "Videos"

      ".cargo"
      ".rustup"
      # TODO: move this to ~/private!
      ".local/share/keyrings"
    ];
    sane.impermanence.dirs.home.cryptClearOnBoot = [
      # cache is probably too big to fit on the tmpfs
      # ".cache"
      ".cache/mozilla"
    ];

    sane.impermanence.dirs.sys.plaintext = mkIf cfg.guest.enable [
      { user = "guest"; group = "users"; directory = "/home/guest"; }
    ];
    users.users.guest = mkIf cfg.guest.enable {
      isNormalUser = true;
      home = "/home/guest";
      uid = config.sane.allocations.guest-uid;
      subUidRanges = [
        { startUid=200000; count=1; }
      ];
      group = "users";
      initialPassword = lib.mkDefault "";
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = [
        # TODO: insert pubkeys that should be allowed in
      ];
    };

    users.users.dhcpcd = mkIf hasDHCP {
      uid = config.sane.allocations.dhcpcd-uid;
    };
    users.groups.dhcpcd = mkIf hasDHCP {
      gid = config.sane.allocations.dhcpcd-gid;
    };

    security.sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };

    services.openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    # affix some UIDs which were historically auto-generated
    users.users.sshd.uid = config.sane.allocations.sshd-uid;
    users.groups.polkituser.gid = config.sane.allocations.polkituser-gid;
    users.groups.sshd.gid = config.sane.allocations.sshd-gid;
    users.groups.systemd-coredump.gid = config.sane.allocations.systemd-coredump-gid;
    users.users.nscd.uid = config.sane.allocations.nscd-uid;
    users.groups.nscd.gid = config.sane.allocations.nscd-gid;
    users.users.systemd-oom.uid = config.sane.allocations.systemd-oom-uid;
    users.groups.systemd-oom.gid = config.sane.allocations.systemd-oom-gid;

    # guarantee determinism in uid/gid generation for users:
    assertions = let
      uidAssertions = builtins.attrValues (builtins.mapAttrs (name: user: {
        assertion = user.uid != null;
        message = "non-deterministic uid detected for: ${name}";
      }) config.users.users);
      gidAssertions = builtins.attrValues (builtins.mapAttrs (name: group: {
        assertion = group.gid != null;
        message = "non-deterministic gid detected for: ${name}";
      }) config.users.groups);
      autoSubAssertions = builtins.attrValues (builtins.mapAttrs (name: user: {
        assertion = !user.autoSubUidGidRange;
        message = "non-deterministic subUids/Guids detected for: ${name}";
      }) config.users.users);
    in uidAssertions ++ gidAssertions ++ autoSubAssertions;
  };
}
