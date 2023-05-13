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
### security
- have `sane.programs` be wrapped such that they run in a cgroup?
    - at least, only give them access to the portion of the fs they *need*.
    - Android takes approach of giving each app its own user: could hack that in here.


## new features:
- add a FTP-accessible file share to servo
    - just /var/www?
- migrate MAME cabinet to nix
    - boot it from PXE from servo?
