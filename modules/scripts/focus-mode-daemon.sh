#!/usr/bin/env bash
# Focus mode daemon: adjusts Hyprland gaps based on tiled window count
# Listens to Hyprland IPC socket for window/workspace events

STATE_FILE="/tmp/hypr-focus-mode"

apply_gaps() {
	# Count tiled (non-floating) windows on the active workspace
	active_ws=$(hyprctl activeworkspace -j | jq '.id')
	count=$(hyprctl clients -j | jq --argjson ws "$active_ws" \
		'[.[] | select(.workspace.id == $ws and .floating == false)] | length')

	case "$count" in
		0|1) gaps_out="300 3200 300 3200"; gaps_in=20 ;;
		2)   gaps_out="150 400 150 400"; gaps_in=100 ;;
		*)   gaps_out="20 20 20 20"; gaps_in=20 ;;
	esac

	hyprctl --batch "keyword general:gaps_out $gaps_out ; keyword general:gaps_in $gaps_in"
}

# --once mode: apply gaps once and exit (used by toggle script)
if [ "$1" = "--once" ]; then
	apply_gaps
	exit 0
fi

trap 'exit 0' TERM INT

socat=$(command -v socat || echo "/run/current-system/sw/bin/socat")
"$socat" -u "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" - | while read -r line; do
	# Exit if focus mode was disabled
	[ ! -f "$STATE_FILE" ] && exit 0

	case "$line" in
		openwindow\>\>*|closewindow\>\>*|movewindow\>\>*|workspace\>\>*|activewindowv2\>\>*)
			apply_gaps
			;;
	esac
done
