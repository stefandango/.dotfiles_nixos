#!/usr/bin/env bash

export TMUX_TMPDIR="${TMUX_TMPDIR:-/run/user/$(id -u)}"

session_count=0
if pgrep tmux > /dev/null 2>&1; then
    sessions=$(tmux list-sessions 2>/dev/null) || true
    if [[ -n "$sessions" ]]; then
        session_count=$(echo "$sessions" | wc -l | tr -d ' ')
    fi
fi

if [[ $session_count -eq 0 ]]; then
    echo ''
else
    if [[ $session_count -le 5 ]]; then
        session_names=$(tmux list-sessions -F "#{session_name}" 2>/dev/null | head -5 | sed ':a;N;$!ba;s/\n/\\n/g') || true
        tooltip="$session_count session(s):\\n$session_names"
    else
        tooltip="$session_count tmux sessions"
    fi
    echo "{\"text\": \"$session_count\", \"tooltip\": \"$tooltip\", \"class\": \"active\"}"
fi
