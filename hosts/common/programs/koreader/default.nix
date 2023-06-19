{ ... }:

{
  sane.programs.koreader = {
    # koreader applies these lua "patches" at boot:
    # - <https://github.com/koreader/koreader/wiki/User-patches>
    # - TODO: upstream this patch to koreader
    # fs.".config/koreader/patches".symlink.target = "${./.}";
    fs.".config/koreader/patches/2-colin-NetworkManager-isConnected.lua".symlink.target = "${./2-colin-NetworkManager-isConnected.lua}";

    # koreader on aarch64 errors if there's no fonts directory (sandboxing thing, i guess)
    fs.".local/share/fonts".dir = {};

    # history, cache, dictionaries...
    # could be more explicit if i symlinked the history.lua file to somewhere it can persist better.
    persist.plaintext = [ ".config/koreader" ];
  };
}
