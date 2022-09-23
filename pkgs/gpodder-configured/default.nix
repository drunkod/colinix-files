{ pkgs
, writeShellScript
, config
}:

(pkgs.symlinkJoin {
  name = "gpodder-configured";
  paths = [ pkgs.gpodder ];
  buildInputs = [ pkgs.makeWrapper ];

  # gpodder keeps all its feeds in a sqlite3 database.
  # we can configure the feeds externally by wrapping gpodder and just instructing it to import
  # a feedlist every time we run it.
  # repeat imports are deduplicated -- assuming network access (not sure how it behaves when disconnected).
  postBuild = ''
    makeWrapper $out/bin/gpodder $out/bin/gpodder-configured \
      --run "$out/bin/gpo import ~/.config/gpodderFeeds.opml"

    # fix up the .desktop file to invoke our wrapped application
    orig_desktop=$(readlink $out/share/applications/gpodder.desktop)
    unlink $out/share/applications/gpodder.desktop
    sed "s:Exec=.*:Exec=$out/bin/gpodder-configured:" $orig_desktop > $out/share/applications/gpodder.desktop
  '';
})
