#!/bin/sh

PIDFILE="/tmp/gamemode-request.pid"

if gamemoded -s 2>/dev/null | grep -q "is active"; then
	if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
		kill "$(cat "$PIDFILE")" 2>/dev/null
		wait "$(cat "$PIDFILE")" 2>/dev/null
	fi
	rm -f "$PIDFILE"
	sleep 0.3
	if gamemoded -s 2>/dev/null | grep -q "is active"; then
		pkill -f 'gamemoderun sleep' 2>/dev/null
		sleep 0.3
	fi
	notify-send -u low "GameMode" "Disabled"
else
	gamemoderun sleep infinity > /dev/null 2>&1 &
	echo "$!" > "$PIDFILE"
	sleep 0.5
	if gamemoded -s 2>/dev/null | grep -q "is active"; then
		notify-send -u low "GameMode" "Enabled"
	else
		notify-send -u low "GameMode" "Failed to enable"
		kill "$(cat "$PIDFILE")" 2>/dev/null
		rm -f "$PIDFILE"
	fi
fi
