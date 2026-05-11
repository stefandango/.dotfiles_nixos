#!/bin/sh

# Probe llama-server (loopback). Health endpoint returns 200 when model is loaded.
HEALTH=$(curl -fsS -o /dev/null -w '%{http_code}' http://127.0.0.1:8080/health 2>/dev/null)

if [ "$HEALTH" != "200" ]; then
	# Distinguish "service down" from "loading" so the bar can show progress.
	if [ "$HEALTH" = "503" ]; then
		printf '{"text": "🦙 …", "tooltip": "llama-server loading model", "class": "idle"}\n'
	else
		printf ''
	fi
	exit 0
fi

MODEL=$(curl -fsS http://127.0.0.1:8080/v1/models 2>/dev/null \
	| sed -n 's/.*"id":"\([^"]*\)".*/\1/p' \
	| head -n1)

if [ -z "$MODEL" ]; then
	printf '{"text": "🦙", "tooltip": "llama-server running — no model info", "class": "idle"}\n'
else
	SHORT=$(basename "$MODEL" .gguf)
	printf '{"text": "🦙 %s", "tooltip": "Loaded: %s\\nEndpoint: http://127.0.0.1:8080/v1", "class": "active"}\n' "$SHORT" "$MODEL"
fi
