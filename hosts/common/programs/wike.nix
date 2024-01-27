{ ... }:
{
  sane.programs.wike = {
    sandbox.method = "bwrap";
    sandbox.extraPaths = [
      # wike sandboxes *itself* with bwrap, and dbus-proxy which, confusingly, causes it to *require* these paths.
      # TODO: these could maybe be mounted empty.
      "/sys/block"
      "/sys/bus"
      "/sys/class"
      "/sys/dev"
      "/sys/devices"
    ];
    # wike probably meant to put everything here in a subdir, but didn't.
    # see: <https://github.com/hugolabe/Wike/issues/176>
    persist.byStore.cryptClearOnBoot = [
      ".cache/webkitgtk"
      ".local/share/webkitgtk"
    ];
    persist.byStore.private = [
      ".local/share/historic.json"  # history
      # .local/share/cookies (probably not necessary to persist?)

      # .local/share/booklists.json (empty; not sure if wike's)
      # .local/share/bookmarks.json (empty; not sure if wike's)
      # .local/share/languages.json (not sure if wike's)
    ];
  };
}
