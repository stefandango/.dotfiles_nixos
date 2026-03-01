#!/bin/sh

if [ -f /tmp/hypr-focus-mode ]; then
	printf '{"text": "󰖯 Focus", "tooltip": "Focus Mode active — click to disable", "class": "active"}\n'
else
	printf '{"text": "", "tooltip": "", "class": "inactive"}\n'
fi
