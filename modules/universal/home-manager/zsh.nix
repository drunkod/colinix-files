{ ... }:
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

    initExtraBeforeCompInit = ''
      # p10k instant prompt
      # run p10k configure to configure, but it can't write out its file :-(
      POWERLEVEL9K_DISABLE_CONFIGURATION_WIZARD=true
    '';
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
        "git"
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
  };
}
