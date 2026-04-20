#!/bin/sh

read -r total used <<EOF
$(free -m | awk '/^Mem:/ {print $2, $3}')
EOF

pct=$((used * 100 / total))
used_gb=$(awk "BEGIN {printf \"%.1f\", $used/1024}")
total_gb=$(awk "BEGIN {printf \"%.1f\", $total/1024}")

if [ "$pct" -ge 90 ]; then
	printf '{"text": "󰍛 %s%%", "tooltip": "Memory: %sG / %sG (%s%%)", "class": "critical"}\n' "$pct" "$used_gb" "$total_gb" "$pct"
elif [ "$pct" -ge 70 ]; then
	printf '{"text": "󰍛 %s%%", "tooltip": "Memory: %sG / %sG (%s%%)", "class": "warning"}\n' "$pct" "$used_gb" "$total_gb" "$pct"
else
	printf '{"text": "", "tooltip": "Memory: %sG / %sG (%s%%)", "class": "normal"}\n' "$used_gb" "$total_gb" "$pct"
fi
