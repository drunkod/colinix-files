{ config, pkgs, lib, ... }:

{
  # docs: https://nixpkgs-manual-sphinx-markedown-example.netlify.app/generated/options-db.xml.html#users-users
  users.users.colin = {
    # sets group to "users" (?)
    isNormalUser = true;
    home = "/home/colin";
    createHome = true;
    homeMode = "0700";
    # i don't get exactly what this is, but nixos defaults to this non-deterministically
    # in /var/lib/nixos/auto-subuid-map and i don't want that.
    subUidRanges = [
      { startUid=100000; count=1; }
    ];
    group = "users";
    extraGroups = [
      "dialout"  # required for modem access (moby)
      "export"  # to read filesystem exports (servo)
      "feedbackd"
      "input"  # for /dev/input/<xyz>: sxmo
      "media"  # servo, for /var/lib/uninsane/media
      "networkmanager"
      "nixbuild"
      "transmission"  # servo, to admin /var/lib/uninsane/media
      "video"  # mobile; for LEDs & maybe for camera?
      "wheel"
      "wireshark"
    ];

    # initial password is empty, in case anything goes wrong.
    # if `colin-passwd` (a password hash) is successfully found/decrypted, that becomes the password at boot.
    initialPassword = lib.mkDefault "";
    passwordFile = lib.mkIf (config.sops.secrets ? "colin-passwd") config.sops.secrets.colin-passwd.path;

    shell = pkgs.zsh;

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

  sane.users.colin = {
    default = true;

    persist.plaintext = [
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
      ".cache/fontconfig"
      ".cache/mesa_shader_cache"
      ".cache/nix"

      # ".cargo"
      # ".rustup"
    ];

    # convenience
    fs."knowledge".symlink.target = "private/knowledge";
    fs."nixos".symlink.target = "dev/nixos";
    fs."Books/servo".symlink.target = "/mnt/servo-media/Books";
    fs."Videos/servo".symlink.target = "/mnt/servo-media/Videos";
    fs."Videos/servo-incomplete".symlink.target = "/mnt/servo-media/incomplete";
    # fs."Music/servo".symlink.target = "/mnt/servo-media/Music";
    fs."Pictures/servo-macros".symlink.target = "/mnt/servo-media/Pictures/macros";

    # used by password managers, e.g. unix `pass`
    fs.".password-store".symlink.target = "knowledge/secrets/accounts";
  };
}
