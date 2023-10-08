#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils -p util-linux

# yeah, this isn't technically a hook, but the hook infrastructure isn't actually
# restricted to stuff that starts with sxmo_hook_ ...
#
# this script is only called by sxmo_autosuspend, which is small, so if i wanted to
# be more proper i could instead re-implement autosuspend + integrations.

. sxmo_common.sh

sxmo_log "going to suspend to crust"

YEARS8_TO_SEC=268435455
suspend_time=99999999 # far away

mnc="$(sxmo_hook_mnc.sh)"
if [ -n "$mnc" ] && [ "$mnc" -gt 0 ] && [ "$mnc" -lt "$YEARS8_TO_SEC" ]; then
	if [ "$mnc" -le 15 ]; then # cronjob imminent
		sxmo_wakelock.sh lock sxmo_waiting_cronjob infinite
		exit 1
	else
		suspend_time=$((mnc - 10))
	fi
fi

sxmo_log "calling suspend with suspend_time <$suspend_time>"

start="$(date "+%s")"
rtcwake -m mem -s "$suspend_time" || exit 1
#We woke up again
time_spent="$(( $(date "+%s") - start ))"

if [ "$((time_spent + 15))" -ge "$suspend_time" ]; then
	sxmo_wakelock.sh lock sxmo_waiting_cronjob infinite
fi

sxmo_hook_postwake.sh

