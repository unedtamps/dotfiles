#!/usr/bin/env bash
# Tokyo Night Wi-Fi menu for Niri + Waybar.
# Requires: NetworkManager (nmcli), wofi, libnotify (notify-send).

set -u

notify() {
    notify-send -a "Wi-Fi" "$1" "${2:-}" 2>/dev/null || true
}

wifi_dev() {
    nmcli -t -f DEVICE,TYPE device 2>/dev/null |
        awk -F: '$2=="wifi" { print $1; exit }'
}

wifi_enabled() {
    [ "$(nmcli radio wifi 2>/dev/null)" = "enabled" ]
}

rescan() {
    nmcli device wifi rescan 2>/dev/null || true
    sleep 1
}

list_networks() {
    local dev
    dev=$(wifi_dev)
    [ -n "$dev" ] || return 1

    nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY device wifi list ifname "$dev" 2>/dev/null |
        awk -F: '
            $2 != "" {
                ssid = $2
                sig = $3 + 0
                sec = $4
                use = $1
                gsub(/\\:/, ":", ssid)
                if (!(ssid in best) || sig > best[ssid]) {
                    best[ssid] = sig
                    secs[ssid] = sec
                    uses[ssid] = use
                }
            }
            END {
                for (s in best) {
                    printf "%s\t%d\t%s\t%s\n", s, best[s], secs[s], uses[s]
                }
            }
        ' | sort -t$'\t' -k2,2nr
}

signal_icon() {
    local sig=$1
    if   [ "$sig" -ge 75 ]; then printf '󰤨'
    elif [ "$sig" -ge 50 ]; then printf '󰤥'
    elif [ "$sig" -ge 25 ]; then printf '󰤢'
    else                         printf '󰤟'
    fi
}

network_is_saved() {
    local ssid=$1
    nmcli -t -f NAME,TYPE connection show 2>/dev/null |
        awk -F: -v s="$ssid" '$2=="802-11-wireless" && $1==s { found=1 } END { exit !found }'
}

connect_network() {
    local ssid=$1 sec=$2 password err

    # Enterprise networks need the full editor.
    if [[ "$sec" == *802.1X* || "$sec" == *WPA-EAP* ]]; then
        notify "Enterprise network" "Opening Network settings"
        setsid nm-connection-editor >/dev/null 2>&1 &
        return
    fi

    # Reuse a saved connection when possible.
    if network_is_saved "$ssid"; then
        if nmcli connection up id "$ssid" >/dev/null 2>&1; then
            notify "Connected" "$ssid"
            return
        fi
    fi

    # Ask for a password only for secured networks.
    if [ -n "$sec" ] && [ "$sec" != "--" ]; then
        password=$(zenity --password --title="Wi-Fi password" --text="Password for $ssid" --width=360 2>/dev/null) || exit 0
        [ -n "$password" ] || exit 0
    fi

    if [ -n "$password" ]; then
        err=$(nmcli device wifi connect "$ssid" password "$password" 2>&1) || {
            notify "Failed to connect" "$ssid"
            printf '%s\n' "$err" >&2
            exit 1
        }
    else
        err=$(nmcli device wifi connect "$ssid" 2>&1) || {
            notify "Failed to connect" "$ssid"
            printf '%s\n' "$err" >&2
            exit 1
        }
    fi

    notify "Connected" "$ssid"
}

main_menu() {
    while true; do
        if ! wifi_enabled; then
            local choice
            choice=$(printf '%s\n' "󰖩  Turn Wi-Fi on" "󰒓  Network settings" |
                wofi --dmenu --prompt "Wi-Fi" --insensitive 2>/dev/null) || exit 0
            case "$choice" in
                *"Turn Wi-Fi on") nmcli radio wifi on; rescan; continue ;;
                *"Network settings") setsid nm-connection-editor >/dev/null 2>&1 & exit 0 ;;
                *) exit 0 ;;
            esac
        fi

        local networks lines choice
        local -A wifi_choices=()
        networks=$(list_networks)
        lines=""

        if [ -n "$networks" ]; then
            while IFS=$'\t' read -r ssid sig sec use; do
                [ -n "$ssid" ] || continue
                local icon lock mark display
                icon=$(signal_icon "$sig")
                lock=""
                [ -n "$sec" ] && [ "$sec" != "--" ] && lock=" 󰌾"
                mark=""
                [ "$use" = "*" ] && mark=" 󰄬"
                display="$icon  $ssid$lock$mark"
                lines+="$display"$'\n'
                wifi_choices["$display"]="$ssid"$'\t'"$sec"
            done <<< "$networks"
        fi

        local rescan_label="󰑓  Rescan"
        local settings_label="󰒓  Network settings"
        local disconnect_label="󰖪  Disconnect"

        lines+="$rescan_label"$'\n'
        wifi_choices["$rescan_label"]="__rescan__"$'\t'""
        lines+="$settings_label"$'\n'
        wifi_choices["$settings_label"]="__settings__"$'\t'""
        if [ "$(nmcli -t -f STATE general 2>/dev/null)" = "connected" ]; then
            lines+="$disconnect_label"$'\n'
            wifi_choices["$disconnect_label"]="__disconnect__"$'\t'""
        fi

        choice=$(printf '%s' "$lines" | wofi --dmenu --prompt "Wi-Fi" --insensitive 2>/dev/null) || exit 0
        [ -n "$choice" ] || exit 0

        local value="${wifi_choices[$choice]:-}"
        [ -n "$value" ] || exit 0
        local ssid="${value%%$'\t'*}"
        local sec="${value#*$'\t'}"

        case "$ssid" in
            __rescan__) rescan; continue ;;
            __settings__) setsid nm-connection-editor >/dev/null 2>&1 & exit 0 ;;
            __disconnect__)
                local dev
                dev=$(wifi_dev)
                [ -n "$dev" ] && nmcli device disconnect "$dev" >/dev/null 2>&1
                notify "Disconnected" "Wi-Fi"
                continue
                ;;
            *) connect_network "$ssid" "$sec" ;;
        esac
        exit 0
    done
}

if [ "${1:-}" = "--list" ]; then
    list_networks
    exit 0
fi

main_menu
