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
    sane.allocations.dhcpcd-gid = mkId 991;
    sane.allocations.dhcpcd-uid = mkId 992;
    sane.allocations.gitea-gid = mkId 993;
    sane.allocations.git-uid = mkId 994;
    sane.allocations.jellyfin-gid = mkId 994;
    sane.allocations.pleroma-gid = mkId 995;
    sane.allocations.jellyfin-uid = mkId 996;
    sane.allocations.acme-gid = mkId 996;
    sane.allocations.pleroma-uid = mkId 997;
    sane.allocations.acme-uid = mkId 998;
    sane.allocations.greeter-uid = mkId 999;
    sane.allocations.greeter-gid = mkId 999;

    sane.allocations.freshrss-uid = mkId 2401;
    sane.allocations.freshrss-gid = mkId 2401;

    sane.allocations.colin-uid = mkId 1000;
    sane.allocations.guest-uid = mkId 1100;

    # found on all hosts
    sane.allocations.sshd-uid = mkId 2001;  # 997
    sane.allocations.sshd-gid = mkId 2001;  # 997
    sane.allocations.polkituser-gid = mkId 2002;  # 998
    sane.allocations.systemd-coredump-gid = mkId 2003;  # 996
    sane.allocations.nscd-uid = mkId 2004;
    sane.allocations.nscd-gid = mkId 2004;
    sane.allocations.systemd-oom-uid = mkId 2005;
    sane.allocations.systemd-oom-gid = mkId 2005;

    # found on graphical hosts
    sane.allocations.nm-iodine-uid = mkId 2101;  # desko/moby/lappy

    # found on desko host
    sane.allocations.usbmux-uid = mkId 2204;
    sane.allocations.usbmux-gid = mkId 2204;


    # originally found on moby host
    sane.allocations.avahi-uid = mkId 2304;
    sane.allocations.avahi-gid = mkId 2304;
    sane.allocations.colord-uid = mkId 2305;
    sane.allocations.colord-gid = mkId 2305;
    sane.allocations.geoclue-uid = mkId 2306;
    sane.allocations.geoclue-gid = mkId 2306;
    sane.allocations.rtkit-uid = mkId 2307;
    sane.allocations.rtkit-gid = mkId 2307;
    sane.allocations.feedbackd-gid = mkId 2308;
  };
}
