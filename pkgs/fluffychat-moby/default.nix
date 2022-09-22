{ pkgs }:

(pkgs.symlinkJoin {
  name = "fluffychat-moby";
  paths = [ pkgs.fluffychat ];
  buildInputs = [ pkgs.makeWrapper ];
  # ordinary fluffychat on moby displays blank window;
  # > Failed to start Flutter renderer: Unable to create a GL context
  # this is temporarily solved by using software renderer
  # - see https://github.com/flutter/flutter/issues/106941
  postBuild = ''
    wrapProgram $out/bin/fluffychat \
      --set LIBGL_ALWAYS_SOFTWARE 1
  '';
})
