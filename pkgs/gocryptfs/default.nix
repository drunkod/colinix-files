{ pkgs, lib, ... }:

(pkgs.gocryptfs.overrideAttrs (upstream: {
  # XXX `su colin` hangs when pam_mount tries to mount a gocryptfs system
  # unless `logger` (util-linux) is accessible from gocryptfs.
  # this is surprising: the code LOOKS like it's meant to handle logging failures.
  # propagating util-linux through either `environment.systemPackages` or `security.pam.mount.additionalSearchPaths` DOES NOT WORK.
  #
  # TODO: see about upstreaming this
  postInstall = ''
    wrapProgram $out/bin/gocryptfs \
      --suffix PATH : ${lib.makeBinPath [ pkgs.fuse pkgs.util-linux ]}
    ln -s $out/bin/gocryptfs $out/bin/mount.fuse.gocryptfs
  '';
}))
