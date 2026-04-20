#!/bin/sh

temp=""
for zone in /sys/class/thermal/thermal_zone*/temp; do
	t=$(cat "$zone" 2>/dev/null)
	if [ -n "$t" ] && [ "$t" -gt 0 ]; then
		t=$((t / 1000))
		if [ -z "$temp" ] || [ "$t" -gt "$temp" ]; then
			temp="$t"
		fi
	fi
done

if [ -z "$temp" ]; then
	printf '{"text": "", "tooltip": "Temperature unavailable", "class": "normal"}\n'
	exit 0
fi

if [ "$temp" -ge 85 ]; then
	printf '{"text": "󰔏 %s°C", "tooltip": "CPU temperature: %s°C", "class": "critical"}\n' "$temp" "$temp"
elif [ "$temp" -ge 70 ]; then
	printf '{"text": "󰔏 %s°C", "tooltip": "CPU temperature: %s°C", "class": "warning"}\n' "$temp" "$temp"
else
	printf '{"text": "", "tooltip": "CPU temperature: %s°C", "class": "normal"}\n' "$temp"
fi
