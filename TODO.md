## refactoring:
### sops/secrets
- move every secret into its own file.
- define SOPS secrets by crawling the ./secrets directory instead of manually defining them.
- see about removing the sops activation script and just using systemd scripts instead.
    - maybe this fixes the multiple "building the system configuration..." messages during nixos-rebuild switch?

### roles
- allow any host to take the role of `uninsane.org`
    - will make it easier to test new services?

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
