#!/bin/sh

# Check if ollama is running
if ! pgrep -x ollama >/dev/null 2>&1; then
	printf ''
	exit 0
fi

# Get running models
MODELS=$(ollama ps 2>/dev/null | tail -n +2)

if [ -z "$MODELS" ]; then
	printf '{"text": "🦙", "tooltip": "Ollama running — no active models", "class": "idle"}\n'
else
	COUNT=$(echo "$MODELS" | wc -l | tr -d ' ')
	NAMES=$(echo "$MODELS" | awk '{print $1}' | paste -sd ', ' -)
	DETAILS=$(echo "$MODELS" | awk '{printf "  %s  (%s, %s)\\n", $1, $4, $5}')
	printf '{"text": "🦙 %s", "tooltip": "Active models:\\n%s", "class": "active"}\n' "$COUNT" "$DETAILS"
fi
