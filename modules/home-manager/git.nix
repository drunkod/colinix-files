{ config, lib, pkgs, ... }:

lib.mkIf config.sane.home-manager.enable
{
  home-manager.users.colin.programs.git = {
    enable = true;
    userName = "colin";
    userEmail = "colin@uninsane.org";

    aliases = { co = "checkout"; };
    extraConfig = {
      # difftastic docs:
      # - <https://difftastic.wilfred.me.uk/git.html>
      diff.tool = "difftastic";
      difftool.prompt = false;
      "difftool \"difftastic\"".cmd = ''${pkgs.difftastic}/bin/difft "$LOCAL" "$REMOTE"'';
      # now run `git difftool` to use difftastic git
    };
  };
}
