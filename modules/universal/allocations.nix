{ lib, ... }:

with lib;
let
  mkId = id: mkOption {
    default = id;
    type = types.int;
  };
in
{
  options = {
    # legacy servo users, some are inconvenient to migrate
    colinsane.allocations.dhcpcd-gid = mkId 991;
    colinsane.allocations.dhcpcd-uid = mkId 992;
    colinsane.allocations.gitea-gid = mkId 993;
    colinsane.allocations.git-uid = mkId 994;
    colinsane.allocations.jellyfin-gid = mkId 994;
    colinsane.allocations.pleroma-gid = mkId 995;
    colinsane.allocations.jellyfin-uid = mkId 996;
    colinsane.allocations.acme-gid = mkId 996;
    colinsane.allocations.pleroma-uid = mkId 997;
    colinsane.allocations.acme-uid = mkId 998;
    colinsane.allocations.greeter-uid = mkId 999;
    colinsane.allocations.greeter-gid = mkId 999;

    colinsane.allocations.colin-uid = mkId 1000;
    colinsane.allocations.guest-uid = mkId 1100;

    # found on all machines
    colinsane.allocations.sshd-uid = mkId 2001;  # 997
    colinsane.allocations.sshd-gid = mkId 2001;  # 997
    colinsane.allocations.polkituser-gid = mkId 2002;  # 998
    colinsane.allocations.systemd-coredump-gid = mkId 2003;  # 996

    # found on graphical machines
    colinsane.allocations.nm-iodine-uid = mkId 2101;  # desko/moby/lappy

    # found on desko machine
    colinsane.allocations.usbmux-uid = mkId 2204;
    colinsane.allocations.usbmux-gid = mkId 2204;


    # originally found on moby machine
    colinsane.allocations.avahi-uid = mkId 2304;
    colinsane.allocations.avahi-gid = mkId 2304;
    colinsane.allocations.colord-uid = mkId 2305;
    colinsane.allocations.colord-gid = mkId 2305;
    colinsane.allocations.geoclue-uid = mkId 2306;
    colinsane.allocations.geoclue-gid = mkId 2306;
    colinsane.allocations.rtkit-uid = mkId 2307;
    colinsane.allocations.rtkit-gid = mkId 2307;
    colinsane.allocations.feedbackd-gid = mkId 2308;
  };
}
