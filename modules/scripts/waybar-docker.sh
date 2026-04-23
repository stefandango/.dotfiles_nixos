#!/bin/sh

COUNT=$(docker info --format '{{json .ContainersRunning}}')

if [ "$COUNT" -gt 0 ]; then
	printf '{"text": "%s", "class": "active"}\n' "$COUNT"
else
	printf ''
fi
