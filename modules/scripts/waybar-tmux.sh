#!/usr/bin/env bash

set -euo pipefail

session_count=0
if pgrep tmux > /dev/null 2>&1; then
    session_count=$(tmux list-sessions 2>/dev/null | wc -l)
fi

if [[ $session_count -eq 0 ]]; then
    echo '{"text": "", "tooltip": "No tmux sessions", "class": "inactive"}'
else
    if [[ $session_count -le 5 ]]; then
        session_names=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | head -5 | sed ':a;N;$!ba;s/\n/\\n/g')
        tooltip="$session_count session(s):\\n$session_names"
    else
        tooltip="$session_count tmux sessions"
    fi
    echo "{\"text\": \"$session_count\", \"tooltip\": \"$tooltip\", \"class\": \"active\"}"
fi
