#!/bin/sh

usage=$(awk '/^cpu / {idle=$5; total=0; for(i=2;i<=NF;i++) total+=$i; printf "%.0f", 100*(total-idle)/total}' /proc/stat)

if [ "$usage" -ge 90 ]; then
	printf '{"text": "󰻠 %s%%", "tooltip": "CPU usage: %s%%", "class": "critical"}\n' "$usage" "$usage"
elif [ "$usage" -ge 70 ]; then
	printf '{"text": "󰻠 %s%%", "tooltip": "CPU usage: %s%%", "class": "warning"}\n' "$usage" "$usage"
else
	printf '{"text": "", "tooltip": "CPU usage: %s%%", "class": "normal"}\n' "$usage"
fi
