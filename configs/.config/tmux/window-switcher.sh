#!/usr/bin/env bash
# Floating read-only tmux window switcher.
# Ctrl+Tab: open, then switch to the next window immediately.
# Ctrl+Shift+Tab: open, then switch to the previous window immediately.
# x: kill the selected window.
# Esc/Enter: close.

set -u

TMUX_BIN="${TMUX_BIN:-tmux}"
SCRIPT="/home/nedo/.config/tmux/window-switcher.sh"
direction=${1:-}

session=$("$TMUX_BIN" display-message -p '#{session_name}' 2>/dev/null </dev/null) || exit 0
[ -n "$session" ] || exit 0

old_stty=$(stty -g 2>/dev/null) || old_stty=""

rebind() {
    "$TMUX_BIN" bind -n C-PageDown display-popup -E -s "bg=#1a1b26,fg=#c0caf5" -S "fg=#7aa2f7" -w 60% -h 40% -T " windows " "$SCRIPT" "--next" </dev/null
    "$TMUX_BIN" bind -n C-PageUp   display-popup -E -s "bg=#1a1b26,fg=#c0caf5" -S "fg=#7aa2f7" -w 60% -h 40% -T " windows " "$SCRIPT" "--prev" </dev/null
    "$TMUX_BIN" bind -n C-Tab      display-popup -E -s "bg=#1a1b26,fg=#c0caf5" -S "fg=#7aa2f7" -w 60% -h 40% -T " windows " "$SCRIPT" "--next" </dev/null
    "$TMUX_BIN" bind -n C-S-Tab    display-popup -E -s "bg=#1a1b26,fg=#c0caf5" -S "fg=#7aa2f7" -w 60% -h 40% -T " windows " "$SCRIPT" "--prev" </dev/null
}

unbind_keys() {
    "$TMUX_BIN" unbind -n C-PageDown 2>/dev/null </dev/null || true
    "$TMUX_BIN" unbind -n C-PageUp   2>/dev/null </dev/null || true
    "$TMUX_BIN" unbind -n C-Tab      2>/dev/null </dev/null || true
    "$TMUX_BIN" unbind -n C-S-Tab    2>/dev/null </dev/null || true
}

cleanup() {
    tput cnorm 2>/dev/null || true
    [ -n "$old_stty" ] && stty "$old_stty" 2>/dev/null || true
    rebind
}
trap cleanup EXIT

unbind_keys
tput civis 2>/dev/null || true
stty -icanon -echo min 1 time 0 2>/dev/null || true

indices=()
names=()
count=0
sel=0
status=""
key=""

load_windows() {
    indices=()
    names=()

    while IFS=$'\t' read -r idx name; do
        [ -n "$idx" ] || continue
        indices+=("$idx")
        names+=("$name")
    done < <("$TMUX_BIN" list-windows -t "$session" -F $'#{window_index}\t#{window_name}' 2>/dev/null </dev/null)

    count=${#indices[@]}
    [ "$count" -gt 0 ] || return 1

    local current
    current=$("$TMUX_BIN" list-windows -t "$session" -F $'#{window_index}\t#{window_active}' 2>/dev/null </dev/null |
        awk -F'\t' '$2=="1" { print $1; exit }')

    sel=0
    for i in "${!indices[@]}"; do
        if [ "${indices[$i]}" = "$current" ]; then
            sel=$i
            break
        fi
    done
    return 0
}

load_windows || exit 0

move_next() {
    sel=$(( (sel + 1) % count ))
    status=""
    "$TMUX_BIN" select-window -t "$session:${indices[$sel]}" 2>/dev/null </dev/null || true
}

move_prev() {
    sel=$(( (sel - 1 + count) % count ))
    status=""
    "$TMUX_BIN" select-window -t "$session:${indices[$sel]}" 2>/dev/null </dev/null || true
}

kill_selected() {
    if [ "$count" -le 1 ]; then
        status="can't kill the last window"
        draw
        return
    fi

    local target="${session}:${indices[$sel]}"
    if "$TMUX_BIN" kill-window -t "$target" 2>/dev/null </dev/null; then
        status="killed window $target"
        load_windows || { status="no windows left"; draw; exit 0; }
    else
        status="failed to kill $target"
    fi
    draw
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
    printf '\n  \e[2mCtrl+Tab next · Ctrl+Shift+Tab prev · x kill · Esc/Enter close\e[0m\n'
    if [ -n "$status" ]; then
        printf '  \e[33m%s\e[0m\n' "$status"
    fi
}

read_key() {
    local k seq x
    IFS= read -rsN1 k || return 1
    if [ "$k" = $'\e' ]; then
        seq=$k
        while IFS= read -rsN1 -t 0.02 x; do
            seq+=$x
        done
        k=$seq
    fi
    key=$k
    return 0
}

# First press already moves one window in the requested direction.
case "$direction" in
    --next) move_next ;;
    --prev) move_prev ;;
esac

draw
while true; do
    read_key || break
    case "$key" in
        $'\e[6;5~'|$'\e[9;5u')  # Ctrl+Tab (legacy or kitty CSI-u)
            move_next
            draw
            ;;
        $'\e[5;5~'|$'\e[9;6u')  # Ctrl+Shift+Tab (legacy or kitty CSI-u)
            move_prev
            draw
            ;;
        x|X)  # kill selected window
            kill_selected
            ;;
        $'\e'|$'\e[27u'|$'\e[13u'|$'\e[13;'*u|q|Q|$'\r'|$'\n')
            break
            ;;
    esac
done
