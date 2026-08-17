#!/usr/bin/env bash
# bash (was sh) so this can source hypr-compat.sh, which papers over the
# hyprlang -> Lua config-manager differences in hyprctl.

STATE_FILE="/tmp/hypr-focus-mode"
PID_FILE="/tmp/hypr-focus-mode-daemon.pid"

. "$HOME/Scripts/hypr-compat.sh"

if [ -f "$STATE_FILE" ]; then
	# Disable focus mode
	rm -f "$STATE_FILE"
	if [ -f "$PID_FILE" ]; then
		kill "$(cat "$PID_FILE")" 2>/dev/null
		rm -f "$PID_FILE"
	fi
	hypr_set_gaps 20 20
	notify-send -u low "Focus Mode" "Disabled"
else
	# Enable focus mode
	touch "$STATE_FILE"
	~/Scripts/focus-mode-daemon.sh &
	echo $! > "$PID_FILE"
	# Apply gaps immediately for current workspace
	~/Scripts/focus-mode-daemon.sh --once
	notify-send -u low "Focus Mode" "Enabled"
fi
