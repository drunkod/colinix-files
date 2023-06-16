{ ... }:

{
  sane.programs.koreader = {
    # koreader on aarch64 errors if there's no fonts directory (sandboxing thing, i guess)
    fs.".local/share/fonts".dir = {};
    # history, cache, dictionaries...
    # could be more explicit if i symlinked the history.lua file to somewhere it can persist better.
    persist.plaintext = [ ".config/koreader" ];
  };
}
