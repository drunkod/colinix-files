{ config, lib, ... }:

lib.mkIf config.sane.home-manager.enable
{
  # we don't need to full zsh dir -- just the history file --
  # but zsh will sometimes backup the history file and we get fewer errors if we do proper mounts instead of symlinks.
  sane.impermanence.home-dirs = [ ".local/share/zsh" ];

  home-manager.users.colin.programs.zsh = {
    enable = true;
    enableSyntaxHighlighting = true;
    enableVteIntegration = true;
    history.ignorePatterns = [ "rm *" ];
    dotDir = ".config/zsh";
    history.path = "/home/colin/.local/share/zsh/history";

    # powerlevel10k prompt config
    initExtraBeforeCompInit = builtins.readFile ./p10k.zsh;
    initExtra = ''
      # zmv is a way to do rich moves/renames, with pattern matching/substitution.
      # see for an example: <https://filipe.kiss.ink/zmv-zsh-rename/>
      autoload -Uz zmv

      # disable `rm *` confirmations
      setopt rmstarsilent

      function nd() {
        mkdir -p "$1";
        pushd "$1";
      }
    '';

    # prezto = oh-my-zsh fork; controls prompt, auto-completion, etc.
    # see: https://github.com/sorin-ionescu/prezto
    prezto = {
      enable = true;
      pmodules = [
        "environment"
        "terminal"
        "editor"
        "history"
        "directory"
        "spectrum"
        "utility"
        "completion"
        "prompt"
        "git"  # TODO: delete? this defines git aliases i don't use, but might be used by prompt
      ];
      prompt.theme = "powerlevel10k";
      utility.safeOps = false;  # disable `mv` confirmation (and supposedly `rm`, too)
    };
  };

  home-manager.users.colin.home.shellAliases = {
    ":q" = "exit";
    # common typos
    "cd.." = "cd ..";
    "cd../" = "cd ../";
    # convenient `cd`-isms
    "knowledge" = "cd ~/knowledge";
    "nixos" = "cd ~/nixos";
    "nixpkgs" = "cd ~/dev/3rd/nixpkgs";
    "ref" = "cd ~/ref";
    "secrets" = "cd ~/knowledge/secrets";
    "uninsane" = "cd ~/dev/uninsane";
  };
}
