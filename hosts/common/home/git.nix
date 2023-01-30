{ lib, pkgs, sane-lib, ... }:

let
  mkCfg = lib.generators.toINI { };
in
{
  sane.user.fs.".config/git/config" = sane-lib.fs.wantedText (mkCfg {
    user.name = "Colin";
    user.email = "colin@uninsane.org";
    alias.co = "checkout";
    # difftastic docs:
    # - <https://difftastic.wilfred.me.uk/git.html>
    diff.tool = "difftastic";
    difftool.prompt = false;
    "difftool \"difftastic\"".cmd = ''${pkgs.difftastic}/bin/difft "$LOCAL" "$REMOTE"'';
    # now run `git difftool` to use difftastic git
  });
}
