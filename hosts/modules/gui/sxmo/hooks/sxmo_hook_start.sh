#!/bin/sh
# this is based on upstream sxmo-utils sxmo_hook_start.sh
# but modified for nixos integration and specialize a bit to my needs
. sxmo_common.sh

# Create xdg user directories, such as ~/Pictures
xdg-user-dirs-update

sxmo_daemons.sh start daemon_manager superd

# let time to superd to start correctly
while ! superctl status > /dev/null 2>&1; do
	sleep 0.5
done

# Periodically update some status bar components
sxmo_hook_statusbar.sh all
sxmo_daemons.sh start statusbar_periodics sxmo_run_aligned.sh 60 \
	sxmo_hook_statusbar.sh periodics

# don't: mako can be started lazily (via dbus activation, i think)
#   superctl start mako
superctl start sxmo_wob
superctl start sxmo_menumode_toggler
superctl start bonsaid
# don't: sway background is managed externally
#   swaymsg output '*' bg "$SXMO_BG_IMG" fill

# To setup initial lock state
sxmo_hook_unlock.sh

# Turn on auto-suspend
if [ -w "/sys/power/wakeup_count" ] && [ -f "/sys/power/wake_lock" ]; then
	superctl start sxmo_autosuspend
fi

# Turn on lisgd
if [ ! -e "$XDG_CACHE_HOME"/sxmo/sxmo.nogesture ]; then
	superctl start sxmo_hook_lisgd
fi

if [ "$(command -v ModemManager)" ]; then
	# Turn on the dbus-monitors for modem-related tasks
	superctl start sxmo_modemmonitor

	# place a wakelock for 120s to allow the modem to fully warm up (eg25 +
	# elogind/systemd would do this for us, but we don't use those.)
	sxmo_wakelock.sh lock sxmo_modem_warming_up 120s
fi

# don't: conky is managed externally
#   superctl start sxmo_conky

# Monitor the battery
superctl start sxmo_battery_monitor

# It watch network changes and update the status bar icon by example
superctl start sxmo_networkmonitor

# The daemon that display notifications popup messages
superctl start sxmo_notificationmonitor

# monitor for headphone for statusbar
superctl start sxmo_soundmonitor

# rotate UI based on physical display angle by default
if [ -n "$SXMO_AUTOROTATE" ]; then
	# TODO: this could use ~/.cache/sxmo/sxmo.autorotate like for lisgd above
	sxmo_daemons.sh start autorotate sxmo_autorotate.sh
fi

# Play a funky startup tune if you want (disabled by default)
#mpv --quiet --no-video ~/welcome.ogg &

# mmsd and vvmd
if [ -f "${SXMO_MMS_BASE_DIR:-"$HOME"/.mms/modemmanager}/mms" ]; then
	superctl start mmsd-tng
fi

if [ -f "${SXMO_VVM_BASE_DIR:-"$HOME"/.vvm/modemmanager}/vvm" ]; then
	superctl start vvmd
fi

# add some warnings if things are not setup correctly
if ! command -v "sxmo_deviceprofile_$SXMO_DEVICE_NAME.sh";  then
	sxmo_notify_user.sh --urgency=critical \
		"No deviceprofile found $SXMO_DEVICE_NAME. See: https://sxmo.org/deviceprofile"
fi

sxmo_migrate.sh state || sxmo_notify_user.sh --urgency=critical \
	"Config needs migration" "$? file(s) in your sxmo configuration are out of date and disabled - using defaults until you migrate (run sxmo_migrate.sh)"