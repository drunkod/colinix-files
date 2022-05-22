# pda build:
rootfs builds (from x86), but img doesn't build:
```sh
$ tail nix log /nix/store/abal7aq9vcbcrpk55n4qzy1g1165yzmb-nixos-disk-image.drv
[    1.889235] EXT4-fs (vda2): mounted filesystem with ordered data mode. Opts:
[    2.432144] random: fast init done
[   14.036820] random: crng init done
[   59.086567] reboot: Restarting system
WARNING: Image format was not specified for 'nixos.raw' and probing guessed raw.
         Automatically detecting the format is dangerous for raw images, write operations on block 0 will be restricted.
         Specify the 'raw' format explicitly to remove the restrictions.
kvm version too old
.qemu-system-aarch64-wrapped: failed to initialize kvm: Function not implemented
```

consider looking at the official mobile-nixos image target to see how it works.


# features/tweaks
- enable sshfs (deskto/lappy)
- enable ddclient (uninsane)
- configure hostnames
- set firefox default search engine
- disable gnome auto-sleep/lock
