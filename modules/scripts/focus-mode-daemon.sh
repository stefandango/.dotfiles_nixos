#!/usr/bin/env bash
# Focus mode daemon: adjusts Hyprland gaps based on tiled window count
# Listens to Hyprland IPC socket for window/workspace events

STATE_FILE="/tmp/hypr-focus-mode"

# `hyprctl keyword` does not work under the Lua config manager, and the 4-value
# gaps_out form has no string spelling there either — it must be a css-gap table.
# hypr_set_gaps handles both.
. "$HOME/Scripts/hypr-compat.sh"

apply_gaps() {
	# Count tiled (non-floating) windows on the active workspace
	active_ws=$(hyprctl activeworkspace -j | jq '.id')
	count=$(hyprctl clients -j | jq --argjson ws "$active_ws" \
		'[.[] | select(.workspace.id == $ws and .floating == false)] | length')

	# Single window: centre it at 40% of the monitor width. The sides must be
	# derived from the width -- gaps_out is subtracted from the work area, and a
	# fixed 3200 per side on a 5120-wide panel gives a negative width, which
	# makes the window vanish.
	mon_width=$(hyprctl monitors -j | jq '[.[] | select(.focused)][0] | (.width / .scale) | floor')
	side=$(( mon_width * 30 / 100 ))

	case "$count" in
		0|1) gaps_out="300 $side 300 $side"; gaps_in=20 ;;
		2)   gaps_out="150 400 150 400"; gaps_in=100 ;;
		*)   gaps_out="20 20 20 20"; gaps_in=20 ;;
	esac

	hypr_set_gaps "$gaps_out" "$gaps_in"
}

# --once mode: apply gaps once and exit (used by toggle script)
if [ "$1" = "--once" ]; then
	apply_gaps
	exit 0
fi

trap 'exit 0' TERM INT

if ! command -v socat >/dev/null; then
	notify-send -u critical "Focus Mode" "socat not found -- gaps will not follow window count"
	exit 1
fi

socat -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
	# Exit if focus mode was disabled
	[ ! -f "$STATE_FILE" ] && exit 0

	case "$line" in
		openwindow\>\>*|closewindow\>\>*|movewindow\>\>*|workspace\>\>*|activewindowv2\>\>*)
			apply_gaps
			;;
	esac
done
