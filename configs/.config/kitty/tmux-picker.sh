#!/usr/bin/env bash

# Session picker for new terminal windows.
#
# - Centered view (inset with margins outside tmux, real popup inside tmux).
# - Type to search immediately.
# - If nothing matches, pressing Enter creates a session named after the query.
# - If the query is a directory, the session starts there.

sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

if [ -n "$TMUX" ]; then
	# Already inside tmux: use a real centered popup.
	fzf_opts=(--popup=center,80%,60%,border-native)
else
	# Fresh terminal: inset the full-screen finder so it looks centered.
	fzf_opts=(--height=100% --margin=20%,20%,10%,10%)
fi

out=$(
	printf "%s\n" "$sessions" | fzf \
		--print-query \
		--prompt="tmux > " \
		--layout=reverse \
		--border=rounded \
		--border-label=" tmux sessions " \
		--padding=0,1 \
		--info=inline \
		"${fzf_opts[@]}"
)
rc=$?

attach_session() {
	if [ -n "$TMUX" ]; then
		exec tmux switch-client -t "$1"
	fi
	exec tmux attach-session -t "$1"
}

new_session() {
	local name="$1"
	local dir="${2:-$PWD}"

	if [ -n "$TMUX" ]; then
		tmux new-session -d -s "$name" -c "$dir" 2>/dev/null
		exec tmux switch-client -t "$name"
	fi

	exec tmux new-session -A -s "$name" -c "$dir"
}

# Esc / Ctrl-C: fall back to the default session.
if [ "$rc" -ne 0 ] && [ -z "$out" ]; then
	new_session main
fi

query=$(printf "%s\n" "$out" | sed -n '1p')
selected=$(printf "%s\n" "$out" | sed -n '2p')

# Existing session selected.
if [ -n "$selected" ]; then
	attach_session "$selected"
fi

# No match: create/directly attach a session from the query.
if [ -n "$query" ]; then
	if [ -d "$query" ]; then
		# Query is a directory: name the session after it and start there.
		new_session "$(basename "$query")" "$query"
	fi

	# tmux forbids ':' and '.' in session names.
	new_session "${query//[:.]/_}"
fi

new_session main
