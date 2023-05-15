## refactoring:
### sops/secrets
- attach secrets to the thing they're used by (sane.programs)
- rework secrets to leverage `sane.fs`
- remove sops activation script as it's covered by my systemd sane.fs impl

### roles
- allow any host to take the role of `uninsane.org`
    - will make it easier to test new services?

### upstreaming
- upstream lemmy nginx integration
- add updateScripts to all my packages in nixpkgs
- fix lightdm-mobile-greeter for newer libhandy
- fix or abandon Whalebird


## improvements:
### security/resilience
- validate duplicity backups!
- encrypt more ~ dirs (~/archives, ~/records, ..?)
    - best to do this after i know for sure i have good backups
- have `sane.programs` be wrapped such that they run in a cgroup?
    - at least, only give them access to the portion of the fs they *need*.
    - Android takes approach of giving each app its own user: could hack that in here.
- canaries for important services
    - e.g. daily email checks; daily backup checks

### user experience
- firefox/librewolf: don't show browserpass/sponsorblock/metamask "first run" on every boot
- moby: improve gPodder launch time
- moby: replace jellyfin-desktop with jellyfin-vue?
    - allows (maybe) to cache media for offline use
    - "newer" jellyfin client
    - not packaged for nix
- find a nice desktop ActivityPub client
- package Nix/NixOS docs for Zeal

### perf
- why does nixos-rebuild switch take 5 minutes when net is flakey?
    - trying to auto-mount servo?
    - something to do with systemd services restarting/stalling
    - maybe wireguard & its refresh operation, specifically?


## new features:
- add a FTP-accessible file share to servo
    - just /var/www?
- migrate MAME cabinet to nix
    - boot it from PXE from servo?
