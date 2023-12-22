#!/bin/sh

COUNT=$(cliphist list | wc -l)

if [ "$COUNT" -gt 0 ]; then
	printf '{"text": "%s"}\n' "$COUNT"
else
	printf ''
fi
