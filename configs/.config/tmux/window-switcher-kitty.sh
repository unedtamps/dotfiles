#!/usr/bin/env bash
# Floating kitty-window tmux window switcher.
# Runs in a separate kitty window so kitty transparency + Niri blur apply.
# Ctrl+Tab: next window + switch immediately.
# Ctrl+Shift+Tab: previous window + switch immediately.
# Esc: close.

set -u

TMUX_BIN="${TMUX_BIN:-tmux}"
direction=${1:-}
session=${2:-}

if [ -z "$session" ]; then
    session=$("$TMUX_BIN" display-message -p '#{session_name}' 2>/dev/null </dev/null) || exit 0
fi
[ -n "$session" ] || exit 0

cleanup() {
    tput cnorm 2>/dev/null || true
}
trap cleanup EXIT

tput civis 2>/dev/null || true

indices=()
names=()
while IFS=$'\t' read -r idx name; do
    [ -n "$idx" ] || continue
    indices+=("$idx")
    names+=("$name")
done < <("$TMUX_BIN" list-windows -t "$session" -F $'#{window_index}\t#{window_name}' 2>/dev/null </dev/null)

count=${#indices[@]}
[ "$count" -gt 0 ] || exit 0

current=$("$TMUX_BIN" list-windows -t "$session" -F $'#{window_index}\t#{window_active}' 2>/dev/null </dev/null |
    awk -F'\t' '$2=="1" { print $1; exit }')
sel=0
for i in "${!indices[@]}"; do
    if [ "${indices[$i]}" = "$current" ]; then
        sel=$i
        break
    fi
done

move_next() {
    sel=$(( (sel + 1) % count ))
    "$TMUX_BIN" select-window -t "$session:${indices[$sel]}" 2>/dev/null </dev/null || true
}

move_prev() {
    sel=$(( (sel - 1 + count) % count ))
    "$TMUX_BIN" select-window -t "$session:${indices[$sel]}" 2>/dev/null </dev/null || true
}

draw() {
    printf '\e[2J\e[H'
    printf '\n  \e[1mtmux windows\e[0m — %s\n\n' "$session"
    local i
    for i in "${!indices[@]}"; do
        if [ "$i" -eq "$sel" ]; then
            printf '  \e[7m  %s  %s  \e[0m\n' "${indices[$i]}" "${names[$i]}"
        else
            printf '    %s  %s\n' "${indices[$i]}" "${names[$i]}"
        fi
    done
    printf '\n  \e[2mCtrl+Tab next · Ctrl+Shift+Tab prev · Esc close\e[0m\n'
}

read_key() {
    local key seq k
    IFS= read -rsn1 key || return 1
    if [ "$key" = $'\e' ]; then
        seq=$key
        while IFS= read -rsn1 -t 0.02 k; do
            seq+=$k
        done
        key=$seq
    fi
    printf '%s' "$key"
}

# First press already moves one window in the requested direction.
case "$direction" in
    --next) move_next ;;
    --prev) move_prev ;;
esac

draw
while true; do
    key=$(read_key) || break
    case "$key" in
        $'\e[6;5~')  # Ctrl+Tab
            move_next
            draw
            ;;
        $'\e[5;5~')  # Ctrl+Shift+Tab
            move_prev
            draw
            ;;
        $'\e'|q|Q|$'\r'|$'\n')
            break
            ;;
    esac
done
