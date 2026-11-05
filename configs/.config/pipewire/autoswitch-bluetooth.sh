#!/usr/bin/env bash
# Auto-switch the default audio sink when a Bluetooth audio device is added/removed.
#
#   Bluetooth connects  -> pick its A2DP sink, make it default, move active streams.
#   Bluetooth disappears -> fall back to the built-in analog output.
#
# Event driven (pactl subscribe), so it never fights a manual sink choice unless
# a new sink actually appears.

set -u

log() { printf '%s %s\n' "$(date '+%F %T')" "$*"; }

current_default() { pactl get-default-sink 2>/dev/null; }

sink_exists() {
	[ -n "$1" ] || return 1
	pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -qxF "$1"
}

# Best Bluetooth sink: prefer an A2DP profile, otherwise the first bluez sink.
best_bluez_sink() {
	pactl list sinks 2>/dev/null | awk '
		BEGIN { RS = ""; FS = "\n" }
		{
			name = ""; prof = ""
			for (i = 1; i <= NF; i++) {
				if ($i ~ /^[[:space:]]*Name: /) {
					name = $i
					sub(/^[[:space:]]*Name: /, "", name)
				} else if ($i ~ /api\.bluez5\.profile/) {
					prof = $i
				}
			}
			if (name ~ /^bluez_output\./) {
				if (prof ~ /a2dp-sink/) { a2dp = name }
				else if (other == "") { other = name }
			}
		}
		END {
			if (a2dp != "") print a2dp
			else if (other != "") print other
		}'
}

# Fallback when Bluetooth goes away: analog stereo first, then any ALSA sink.
fallback_sink() {
	pactl list short sinks 2>/dev/null | awk '$2 ~ /^alsa_output/ {
		if ($2 ~ /analog-stereo/ && analog == "") analog = $2
		if (first == "") first = $2
	}
	END {
		if (analog != "") print analog
		else if (first != "") print first
	}'
}

set_default_and_move() {
	local sink=$1 id
	[ -n "$sink" ] || return 0
	[ "$sink" = "$(current_default)" ] || pactl set-default-sink "$sink" >/dev/null 2>&1
	while read -r id; do
		[ -n "$id" ] || continue
		pactl move-sink-input "$id" "$sink" >/dev/null 2>&1 || true
	done < <(pactl list short sink-inputs 2>/dev/null | awk '{print $1}')
}

log "watching for Bluetooth audio devices (default: $(current_default))"

# -oL: pactl block-buffers its own stdout when writing to a pipe, so events
# would otherwise arrive in bursts instead of as they happen.
stdbuf -oL pactl subscribe 2>/dev/null | while read -r event; do
	if [[ $event =~ Event\ \'new\'\ on\ sink\ \#([0-9]+) ]]; then
		# Give WirePlumber a moment to settle the profile before choosing.
		sleep 1
		sink=$(best_bluez_sink)
		if [ -n "$sink" ]; then
			if [ "$sink" != "$(current_default)" ]; then
				log "Bluetooth sink appeared: $sink -> switching default"
				set_default_and_move "$sink"
			fi
		fi
	elif [[ $event =~ Event\ \'remove\'\ on\ sink\ \#([0-9]+) ]]; then
		def=$(current_default)
		if [ -n "$def" ] && ! sink_exists "$def"; then
			fb=$(fallback_sink)
			if [ -n "$fb" ]; then
				log "default sink $def disappeared -> falling back to $fb"
				set_default_and_move "$fb"
			fi
		fi
	fi
done
