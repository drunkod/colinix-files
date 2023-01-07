{ lib, ... }:

rec {
  wanted = lib.mergeAttrs { wantedBeforeBy = [ "multi-user.target" ]; };
  wantedSymlink = symlink: wanted { inherit symlink; };
  wantedSymlinkTo = target: wantedSymlink { inherit target; };
  wantedText = text: wantedSymlink { inherit text; };
}

