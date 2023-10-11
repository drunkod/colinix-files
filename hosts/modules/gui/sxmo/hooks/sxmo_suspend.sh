#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils -p rtl8723cs-wowlan -p time -p util-linux

# yeah, this isn't technically a hook, but the hook infrastructure isn't actually
# restricted to stuff that starts with sxmo_hook_ ...
#
# this script is only called by sxmo_autosuspend, which is small, so if i wanted to
# be more proper i could instead re-implement autosuspend + integrations.
#
# N.B.: if any wake locks are acquired between invocation of this script and the
# rtcwake call below, suspend will fail -- even if those locks are released during
# the same period.
#
# this is because the caller of this script writes /sys/power/wakeup_count, and the
# kernel checks consistency with that during the actual suspend request.
# see: <https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-power>
#
# for this reason, keep this script as short as possible.
#
# common sources of wakelocks (which one may wish to reduce) include:
# - `sxmo_led.sh blink` (every 2s, by default)

suspend_time=300

# TODO: don't do this wowlan stuff every single time.
# - it's costly (can take like 1sec)
# - it seems to actually block suspension quite often
#   - possibly rtl8723cs takes time to apply wowlan changes during which suspension is impossible
# alternative is to introduce some layer of cache:
# - do so in a way such that WiFi connection state changes invalidate the cache
#   - because wowlan enable w/o connection may well behave differently than w/ connection
# - calculating IP addr from link, and then caching on the args we call our helper with may well suffice
doas rtl8723cs-wowlan enable-clean
# wake on ssh
doas rtl8723cs-wowlan tcp --dest-port 22
# wake on notification (ntfy/Universal Push)
doas rtl8723cs-wowlan tcp --source-port 2587
# wake if someone doesn't know how to route to us, because that could obstruct the above
doas rtl8723cs-wowlan arp --dest-ip SELF

echo "calling suspend for duration: $suspend_time"

start="$(date "+%s")"
rtcwake -m mem -s "$suspend_time" || exit 1
#We woke up again
time_spent="$(( $(date "+%s") - start ))"
echo "suspended for $time_spent seconds"

sxmo_hook_postwake.sh

