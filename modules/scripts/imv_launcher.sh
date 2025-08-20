#!/usr/bin/env bash

# Simple launcher for imv image viewer
# Usage: imv_launcher.sh [directory|file]

DEFAULT_DIR="$HOME/Pictures"

if [[ $# -eq 0 ]]; then
    # No arguments - open Pictures directory
    if [[ -d "$DEFAULT_DIR" ]]; then
        exec imv "$DEFAULT_DIR"
    else
        exec imv .
    fi
elif [[ -f "$1" ]]; then
    # Single file provided
    exec imv "$1"
elif [[ -d "$1" ]]; then
    # Directory provided
    exec imv "$1"
else
    # Invalid path, fallback to current directory
    exec imv .
fi