#!/bin/sh

# CPU usage over the interval between polls.
#
# A single /proc/stat read gives you the average since boot, which on a machine
# that has been up for days is a flat, useless number that never moves. Real
# usage is a delta between two samples, so stash the previous one and diff
# against it. The module's own poll interval supplies the window — no in-script
# sleep, which would block the bar on every tick.

STATE="${XDG_RUNTIME_DIR:-/tmp}/waybar-cpu.prev"

# $5 is idle and $6 is iowait; both are time the CPU wasn't running work.
set -- $(awk '/^cpu / {t=0; for(i=2;i<=NF;i++) t+=$i; print t, $5+$6}' /proc/stat)
total=$1
idle=$2

usage=""
if [ -r "$STATE" ]; then
	set -- $(cat "$STATE" 2>/dev/null)
	ptotal=$1
	pidle=$2
	if [ -n "${ptotal:-}" ] && [ -n "${pidle:-}" ]; then
		dt=$((total - ptotal))
		di=$((idle - pidle))
		# dt<=0 means the counters wrapped or the file was stale/garbage.
		[ "$dt" -gt 0 ] && usage=$(awk "BEGIN {printf \"%.0f\", 100*($dt-$di)/$dt}")
	fi
fi

printf '%s %s\n' "$total" "$idle" > "$STATE"

# First run after boot has no previous sample; fall back to since-boot rather
# than showing nothing.
if [ -z "$usage" ]; then
	usage=$(awk "BEGIN {printf \"%.0f\", 100*($total-$idle)/$total}")
fi

if [ "$usage" -ge 90 ]; then
	printf '{"text": "󰻠  %s%%", "tooltip": "CPU usage: %s%%", "class": "critical"}\n' "$usage" "$usage"
elif [ "$usage" -ge 70 ]; then
	printf '{"text": "󰻠  %s%%", "tooltip": "CPU usage: %s%%", "class": "warning"}\n' "$usage" "$usage"
else
	printf '{"text": "", "tooltip": "CPU usage: %s%%", "class": "normal"}\n' "$usage"
fi
