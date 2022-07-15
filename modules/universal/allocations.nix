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
    colinsane.allocations.dhcpcd-gid = mkId 991;
    colinsane.allocations.dhcpcd-uid = mkId 992;
    colinsane.allocations.gitea-gid = mkId 993;  # servo
    colinsane.allocations.git-uid = mkId 994;  # servo
    colinsane.allocations.jellyfin-gid = mkId 994;  # servo

    colinsane.allocations.usbmux-gid = mkId 995;  # desko
    colinsane.allocations.usbmux-uid = mkId 996;  # desko

    colinsane.allocations.pleroma-gid = mkId 995;  # servo
    colinsane.allocations.jellyfin-uid = mkId 996;  # servo
    colinsane.allocations.acme-gid = mkId 996;  # servo
    colinsane.allocations.pleroma-uid = mkId 997;  # servo

    colinsane.allocations.nm-iodine-uid = mkId 998;  # desko/moby/lappy

    colinsane.allocations.acme-uid = mkId 998;  # servo
    colinsane.allocations.greeter-uid = mkId 999;
    colinsane.allocations.greeter-gid = mkId 999;
    colinsane.allocations.colin-uid = mkId 1000;
    colinsane.allocations.sshd-uid = mkId 2001;  # 997
    colinsane.allocations.sshd-gid = mkId 2001;  # 997
    colinsane.allocations.polkituser-gid = mkId 2002;  # 998
    colinsane.allocations.systemd-coredump-gid = mkId 2003;  # 996

    # originally found on moby machine
    colinsane.allocations.avahi-uid = mkId 2104;
    colinsane.allocations.avahi-gid = mkId 2104;
    colinsane.allocations.colord-uid = mkId 2105;
    colinsane.allocations.colord-gid = mkId 2105;
    colinsane.allocations.geoclue-uid = mkId 2106;
    colinsane.allocations.geoclue-gid = mkId 2106;
    colinsane.allocations.rtkit-uid = mkId 2107;
    colinsane.allocations.rtkit-gid = mkId 2107;
    colinsane.allocations.feedbackd-gid = mkId 2108;
  };
}
