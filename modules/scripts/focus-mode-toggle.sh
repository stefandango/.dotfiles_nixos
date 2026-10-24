#!/usr/bin/env bash
# bash (not sh) so this can source hypr-compat.sh, which wraps the
# `hyprctl eval` calls that Hyprland's Lua config manager requires.

STATE_FILE="/tmp/hypr-focus-mode"
PID_FILE="/tmp/hypr-focus-mode-daemon.pid"

. "$HOME/Scripts/hypr-compat.sh"

if [ -f "$STATE_FILE" ]; then
	# Disable focus mode
	rm -f "$STATE_FILE"
	# Killing the PID alone leaves the daemon's socat | while-read pipeline
	# running, and it piles up a duplicate on every off/on cycle.
	pkill -f 'Scripts/focus-mode-daemon.sh'
	rm -f "$PID_FILE"
	hypr_set_gaps 20 20
	notify-send -u low "Focus Mode" "Disabled"
else
	# Enable focus mode
	touch "$STATE_FILE"
	pkill -f 'Scripts/focus-mode-daemon.sh'
	~/Scripts/focus-mode-daemon.sh &
	echo $! > "$PID_FILE"
	# Apply gaps immediately for current workspace
	~/Scripts/focus-mode-daemon.sh --once
	notify-send -u low "Focus Mode" "Enabled"
fi
