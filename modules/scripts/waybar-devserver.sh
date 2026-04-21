#!/bin/sh

# Check common dev server ports
ports="3000 3001 4200 5000 5173 5174 8000 8080 8888"
active=""
count=0

for port in $ports; do
	if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
		count=$((count + 1))
		active="${active}  :${port}\n"
	fi
done

if [ "$count" -eq 0 ]; then
	printf '{"text": "", "tooltip": "", "class": "inactive"}\n'
else
	printf '{"text": "%s", "tooltip": "Dev servers running:\\n%s", "class": "active"}\n' "$count" "$active"
fi
