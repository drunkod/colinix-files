{ ... }:

rec {
  wantedSymlink = symlink: {
    inherit symlink;
    wantedBeforeBy = [ "multi-user.target" ];
  };
  wantedSymlinkTo = target: wantedSymlink { inherit target; };
  wantedText = text: wantedSymlink { inherit text; };
}

