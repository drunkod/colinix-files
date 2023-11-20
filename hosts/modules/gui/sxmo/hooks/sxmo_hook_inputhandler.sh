#!/usr/bin/env nix-shell
#!nix-shell -i bash -p coreutils -p pulseaudio

# input map considerations
# - using compound actions causes delays.
#   e.g. if volup->volup is a distinct action from volup, then single-volup action is forced to wait the maximum button delay.
# - actions which are to be responsive should therefore have a dedicated key.
# - a dedicated "kill" combo is important for unresponsive fullscreen apps, because appmenu doesn't show in those
#   - although better may be to force appmenu to show over FS apps
# - bonsai mappings are static, so buttons can't benefit from non-compounding unless they're mapped accordingly for all lock states
#   - this limitation could be removed, but with work
#
# proposed future design:
# - when unlocked:
#   - volup1   -> app menu
#   - voldown1 -> toggle keyboard
#   - pow1 -> volup1 -> volume up
#   - pow1 -> voldown1 -> volume down
#   - pow2 -> screen off
#   - pow3 -> kill app
# - when locked:
#   - volup1 -> volume up
#   - voldown1 -> volume down
#   - pow1 -> screen on
#   - pow2 -> toggle player
# benefits
# - volup and voldown are able to be far more responsive
#   - which means faster vkbd, menus, volume adjustment (when locked)
# limitations
# - terminal is unmapped. that could be mapped to pow1?
# - wm menu is unmapped. but i never used that much anyway

# increments to use for volume adjustment
VOL_INCR_1=5
VOL_INCR_2=10
VOL_INCR_3=15

# replicating the naming from upstream sxmo_hook_inputhandler.sh...
ACTION="$1"
STATE=$(cat "$SXMO_STATE")


handle_with() {
  echo "sxmo_hook_inputhandler.sh: STATE=$STATE ACTION=$ACTION: handle_with: $@"
  "$@"
  exit 0
}

# handle_with_state_toggle() {
#   # - unlock,lock => screenoff
#   # - screenoff => unlock
#   #
#   # probably not handling proximity* correctly here
#   case "$STATE" in
#     *lock)
#       respond_with sxmo_state.sh set screenoff
#     *)
#       respond_with sxmo_state.sh set unlock
#   esac
# }

# state is one of:
# - "unlock" => normal operation; display on and touchscreen on
# - "screenoff" => display off and touchscreen off
# - "lock" => display on but touchscreen disabled
# - "proximity{lock,unlock}" => intended for when in a phone call

if [ "$STATE" = "unlock" ]; then
  case "$ACTION" in
    # powerbutton_one: intentional default to no-op
    # powerbutton_two: intentional default to screenoff
    "powerbutton_three")
      # power thrice: kill active window
      handle_with sxmo_killwindow.sh
      ;;

    "volup_one")
      # volume up once: app-specific menu w/ fallback to SXMO system menu
      handle_with sxmo_appmenu.sh
      ;;
    # volup_two: intentionally defaulted for volume control
    "volup_three")
      # volume up thrice: DE menu
      handle_with sxmo_wmmenu.sh
      ;;

    "voldown_one")
      # volume down once: toggle keyboard
      handle_with sxmo_keyboard.sh toggle
      ;;
    # voldown_two: intentionally defaulted for volume control
    "voldown_three")
      # volume down thrice: launch terminal
      handle_with sxmo_terminal.sh
      ;;
  esac
fi

if [ "$STATE" = "screenoff" ]; then
  case "$ACTION" in
    "powerbutton_two")
      # power twice => toggle media player
      handle_with playerctl play-pause
      ;;
    "powerbutton_three")
      # power once during deep sleep often gets misread as power three, so treat these same
      handle_with sxmo_state.sh set unlock
      ;;
  esac
fi

# default actions
case "$ACTION" in
  "powerbutton_one")
    # power once => unlock
    handle_with sxmo_state.sh set unlock
    ;;
  "powerbutton_two")
    # power twice => screenoff
    handle_with sxmo_state.sh set screenoff
    ;;
  # powerbutton_three: intentional no-op because overloading the kill-window handler is risky

  "volup_one")
    handle_with pactl set-sink-volume @DEFAULT_SINK@ +"$VOL_INCR_1%"
    ;;
  "volup_two")
    handle_with pactl set-sink-volume @DEFAULT_SINK@ +"$VOL_INCR_2%"
    ;;
  "volup_three")
    handle_with pactl set-sink-volume @DEFAULT_SINK@ +"$VOL_INCR_3%"
    ;;

  "voldown_one")
    handle_with pactl set-sink-volume @DEFAULT_SINK@ -"$VOL_INCR_1%"
    ;;
  "voldown_two")
    handle_with pactl set-sink-volume @DEFAULT_SINK@ -"$VOL_INCR_2%"
    ;;
  "voldown_three")
    handle_with pactl set-sink-volume @DEFAULT_SINK@ -"$VOL_INCR_3%"
    ;;
esac


handle_with echo "no-op"
