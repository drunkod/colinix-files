# Tangram is a GTK/webkit browser
# it views each tab as a distinct application, persisted, and where the 'home' button action is specific to each tab.
# it supports ephemeral tabs, but UX is heavily geared to GCing those as early as possible.

{ ... }:
{
  sane.programs.tangram = {
    persist.private = [
      ".cache/Tangram"
      ".local/share/Tangram"
    ];
  };
}
