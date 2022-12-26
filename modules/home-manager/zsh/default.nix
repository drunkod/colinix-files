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

    # defaultKeymap = "vicmd"; # vim normal mode (cmd mode)

    # powerlevel10k prompt config
    # p10k.zsh is the auto-generated config, and i overwrite those defaults here, below.
    initExtraBeforeCompInit = (builtins.readFile ./p10k.zsh) + ''
      # powerlevel10k launches a gitstatusd daemon to accelerate git prompt queries.
      # this keeps open file handles for any git repo i touch for 60 minutes (by default).
      # that prevents unmounting whatever device the git repo is on -- particularly problematic for ~/private.
      # i can disable gitstatusd and get slower fallback git queries:
      # - either universally
      # - or selectively by path
      # see: <https://github.com/romkatv/powerlevel10k/issues/246>
      typeset -g POWERLEVEL9K_VCS_DISABLED_DIR_PATTERN='(/home/colin/private/*|/home/colin/knowledge/*)'
      # typeset -g POWERLEVEL9K_DISABLE_GITSTATUS=true

      # show user@host also when logged into the current machine.
      # default behavior is to show it only over ssh.
      typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION='$P9K_CONTENT'
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
        # configures jobs to persist after shell exit; other basic niceties
        "environment"
        # auto-titles terminal (e.g. based on cwd)
        "terminal"
        # configures shortcuts like Ctrl+U=undo, Ctrl+L=clear
        "editor"
        # adds `history-stat` alias, setopts for good history defaults
        "history"
        # sets AUTO_CD, adds `d` alias to list directory stack, and `1`-`9` to cd that far back the stack
        "directory"
        # helpers for term colors and styling. used by prompts? might be unnecessary
        "spectrum"
        # configures aliases like `ll`, `la`, disables globbing for things like rsync
        # adds aliases like `get` to fetch a file. also adds `http-serve` alias??
        "utility"
        # tab completion. requires `utility` module prior to loading
        # TODO: enable AUTO_PARAM_SLASH
        "completion"
        "prompt"
        # TODO: enable syntax-highlighting ?
      ];
      prompt.theme = "powerlevel10k";
      utility.safeOps = false;  # disable `mv` confirmation (and supposedly `rm`, too)
      # editor.keymap = "vi";
    };

    dirHashes = {
      # convenient `cd`-isms
      "3rd" = "/home/colin/dev/3rd";
      "dev" = "/home/colin/dev";
      "knowledge" = "/home/colin/knowledge";
      "nixos" = "/home/colin/nixos";
      "nixpkgs" = "/home/colin/dev/3rd/nixpkgs";
      "ref" = "/home/colin/ref";
      "secrets" = "/home/colin/knowledge/secrets";
      "tmp" = "/home/colin/tmp";
      "uninsane" = "/home/colin/dev/uninsane";
      "Videos" = "/home/colin/Videos";
    };
  };

  home-manager.users.colin.home.shellAliases = {
    ":q" = "exit";
    # common typos
    "cd.." = "cd ..";
    "cd../" = "cd ../";
  };
}
