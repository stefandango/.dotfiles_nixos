#!/bin/sh

COUNT=$(docker info --format '{{json .ContainersRunning}}')

if [ "$COUNT" -gt 0 ]; then
	printf '{"text": "%s"}\n' "$COUNT"
else
	printf ''
fi
