{ config, pkgs, lib, ... }:

{
  # docs: https://nixpkgs-manual-sphinx-markedown-example.netlify.app/generated/options-db.xml.html#users-users
  users.users.alex = {
    # sets group to "users" (?)
    isNormalUser = true;
    home = "/home/alex";
    # i don't get exactly what this is, but nixos defaults to this non-deterministically
    # in /var/lib/nixos/auto-subuid-map and i don't want that.
    subUidRanges = [
      { startUid=100000; count=1; }
    ];
    group = "users";
    extraGroups = [
      "clightning"  # servo, for clightning-cli
      "dialout"  # required for modem access (moby)
      "export"  # to read filesystem exports (servo)
      "feedbackd"  # moby, so `fbcli` can control vibrator and LEDs
      "input"  # for /dev/input/<xyz>: sxmo
      "media"  # servo, for /var/lib/uninsane/media
      "networkmanager"
      "nixbuild"
      "systemd-journal"  # allows to view other user's journals (esp system users)
      "transmission"  # servo, to admin /var/lib/uninsane/media
      "video"  # mobile; for LEDs & maybe for camera?
      "wheel"
      "wireshark"
    ];

    # initial password is empty, in case anything goes wrong.
    # if `alex-passwd` (a password hash) is successfully found/decrypted, that becomes the password at boot.
    initialPassword = lib.mkDefault "";
    hashedPasswordFile = lib.mkIf (config.sops.secrets ? "alex-passwd") config.sops.secrets.alex-passwd.path;

    shell = pkgs.zsh;

    # mount encrypted stuff at login
    # some other nix pam users:
    # - <https://github.com/g00pix/nixconf/blob/32c04f6fa843fed97639dd3f09e157668d3eea1f/profiles/sshfs.nix>
    # - <https://github.com/lourkeur/distro/blob/11173454c6bb50f7ccab28cc2c757dca21446d1d/nixos/profiles/users/louis-full.nix>
    # - <https://github.com/dnr/sample-nix-code/blob/03494480c1fae550c033aa54fd96aeb3827761c5/nixos/laptop.nix>
    pamMount = let
      hasPrivate = config.fileSystems ? "/home/alex/private";
      priv = config.fileSystems."/home/alex/private";
    in lib.mkIf hasPrivate {
      fstype = priv.fsType;
      path = priv.device;
      mountpoint = priv.mountPoint;
      options = builtins.concatStringsSep "," priv.options;
    };
  };

  environment.etc."/security/capability.conf".text = ''
    # The pam_cap.so module accepts the following arguments:
    #
    #   debug         - be more verbose logging things (unused by pam_cap for now)
    #   config=<file> - override the default config for the module with file
    #   keepcaps      - workaround for applications that setuid without this
    #   autoauth      - if you want pam_cap.so to always succeed for the auth phase
    #   default=<iab> - provide a fallback IAB value if there is no '*' rule
    #
    # format:
    # <CAP>[,<CAP>...] USER|@GROUP|*
    #
    # the part of each line before the delimiter (" \t\n") is parsed with `cap_iab_from_text`.
    # so each CAP can be prefixed to indicate which set it applies to:
    # [!][^][%]<CAP>
    # where ! adds to the NB set (bounding)
    #       ^ for AI (ambient + inherited)
    #       % (or empty) for I (inherited)
    #
    # special capabilities "all" and "none" enable all/none of the caps known to the system.

    ^cap_net_admin,^cap_net_raw alex
    # include this `none *` line otherwise non-matching users get maximum inheritable capabilities
    none *
  '';

  # grant myself extra capabilities for systemd sessions so that i can e.g.:
  # - run wireshark without root/setuid
  # - (incidentally) create new network devices/routes without root/setuid, which ought to be useful for sandboxing if i deploy that right.
  # default systemd includes cap_wake_alarm unless we specify our own capabilityAmbientSet; might be helpful for things like rtcwake?
  #
  # userName and uid have to be explicitly set here, to pass systemd's sanity checks.
  # other values like `home`, `shell` can be omitted and systemd will grab those from other sources (/etc/passwd)
  #
  # user records are JSON dicts, keys are found in systemd: src/shared/user-record.c:user_record_load
  # notable keys:
  # - capabilityBoundingSet
  # - capabilityAmbientSet
  # - service
  # - privileged
  #
  # XXX 2024/01/30: as of systemd 255, ambient capabilities are broken; not set at login and not usable via systemd --user services.
  # environment.etc."userdb/alex.user".text = ''
  #   {
  #     "userName" : "alex",
  #     "uid": ${builtins.toString config.users.users.alex.uid},
  #     "capabilityAmbientSet": [
  #       "cap_net_admin",
  #       "cap_net_raw"
  #     ]
  #   }
  # '';

  sane.users.alex = {
    default = true;

    persist.byStore.plaintext = [
      "archive"
      "dev"
      # TODO: records should be private
      "records"
      "ref"
      "tmp"
      "use"
      "Books"
      "Music"
      "Pictures"
      "Videos"

      # these are persisted simply to save on RAM.
      # ~/.cache/nix can become several GB.
      # fontconfig and mesa_shader_cache are < 10 MB.
      # TODO: integrate with sane.programs.sandbox?
      ".cache/fontconfig"
      ".cache/mesa_shader_cache"
      ".cache/nix"

      # ".cargo"
      # ".rustup"
    ];

    # fs.".cargo".symlink.target = "/tmp/alex-cargo";

    # convenience
    fs."knowledge".symlink.target = "private/knowledge";
    fs."nixos".symlink.target = "dev/nixos";
    fs."Books/servo".symlink.target = "/mnt/servo-media/Books";
    fs."Videos/servo".symlink.target = "/mnt/servo-media/Videos";
    # fs."Music/servo".symlink.target = "/mnt/servo-media/Music";
    fs."Pictures/servo-macros".symlink.target = "/mnt/servo-media/Pictures/macros";
  };
}
