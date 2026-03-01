#!/bin/sh

if gamemoded -s 2>/dev/null | grep -q "is active"; then
	printf '{"text": "󰊴 Game", "tooltip": "GameMode active — click to disable", "class": "active"}\n'
else
	printf '{"text": "", "tooltip": "", "class": "inactive"}\n'
fi
