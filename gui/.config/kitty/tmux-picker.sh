#!/usr/bin/env bash

sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

choices="$sessions"$'\n'"[new session]"

selected=$(
    printf "%s\n" "$choices" | \
    fzf \
        --prompt="tmux > " \
        --height=40% \
        --layout=reverse \
        --border
)

if [ -z "$selected" ]; then
    exec tmux new-session -A -s main
fi

if [ "$selected" = "[new session]" ]; then
    read -rp "Session name: " name

    [ -z "$name" ] && name="main"

    exec tmux new-session -A -s "$name"
fi

exec tmux attach-session -t "$selected"
