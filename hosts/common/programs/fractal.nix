{ pkgs, ... }:
{
  sane.programs.fractal = {
    # package = pkgs.fractal-latest;
    package = pkgs.fractal-next;

    # XXX by default fractal stores its state in ~/.local/share/<UUID>.
    # after logging in, manually change ~/.local/share/keyrings/... to point it to some predictable subdir.
    # then reboot (so that libsecret daemon re-loads the keyring...?)
    persist.private = [ ".local/share/fractal" ];
  };
}
