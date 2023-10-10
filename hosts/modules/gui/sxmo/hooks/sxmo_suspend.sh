#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils -p rtl8723cs-wowlan -p time -p util-linux

# yeah, this isn't technically a hook, but the hook infrastructure isn't actually
# restricted to stuff that starts with sxmo_hook_ ...
#
# this script is only called by sxmo_autosuspend, which is small, so if i wanted to
# be more proper i could instead re-implement autosuspend + integrations.

suspend_time=300

rtl8723cs-wowlan enable-clean
# wake on ssh
rtl8723cs-wowlan tcp --dest-port 22
# wake on notification (ntfy/Universal Push)
rtl8723cs-wowlan tcp --source-port 2587
# wake if someone doesn't know how to route to us, because that could obstruct the above
rtl8723cs-wowlan arp --dest-ip 10.78.79.54

echo "calling suspend for duration: $suspend_time"

# XXX: run this in `env` to get the `time` binary instead of the builtin
elapsed="$(env time -f "%e" rtcwake -m mem -s $suspend_time)" || exit 1

echo "suspended for $elapsed seconds"

sxmo_hook_postwake.sh

