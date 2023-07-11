# Tangram is a GTK/webkit browser
# it views each tab as a distinct application, persisted, and where the 'home' button action is specific to each tab.
# it supports ephemeral tabs, but UX is heavily geared to GCing those as early as possible.

{ lib, pkgs, ... }:
let
  dconfProfile = pkgs.writeTextFile {
    name = "dconf-tangram-profile";
    destination = "/etc/dconf/profile/tangram";
    text = ''
      user-db:tangram
      system-db:site
    '';
  };
  initTangramDconf = pkgs.writeShellScript "init-tangram-dconf" ''
    test -f "$1" || ${lib.getBin pkgs.dconf}/bin/dconf compile "$1" "${pkgs.emptyDirectory}"
  '';
in
{
  sane.programs.tangram = {
    # XXX(2023/07/08): running on moby without disabling the webkit sandbox fails, with:
    # - `bwrap: Can't make symlink at /var/run: File exists`
    # see epiphany.nix for more info
    package = pkgs.tangram.overrideAttrs (upstream: {
      # --set DCONF_PROFILE "${dconfProfile}/etc/dconf/profile/tangram"
      preFixup = ''
        gappsWrapperArgs+=(
          --set WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS "1"
          --set DCONF_PROFILE "${dconfProfile}/etc/dconf/profile/tangram"
        );
      '' + (upstream.preFixup or "");
    });

    persist.private = [
      ".cache/Tangram"
      ".local/share/Tangram"
      # dconf achieves atomic writes via `mv`, so a symlink doesn't work
      # moreover, i have to persist the *whole* directory:
      # - `user-db:tangram/user` causes a schema failure
      # - bind-mounting `~/private/.config/dconf/tangram` causes dconf to try a cross-fs `mv`, which fails
      # - dconf provides no way to specify an alternate ~/.config/dconf dir, except by overriding XDG_CONFIG_HOME
      # { type = "file"; path = ".config/dconf/tangram"; method = "bind"; }
      ".config/dconf"
    ];

    fs."private/.config/dconf/tangram".generated = {
      acl.mode = "0644";
      command = [
        "${initTangramDconf}"
        "/home/colin/private/.config/dconf/tangram"
      ];
    };
  };
}
