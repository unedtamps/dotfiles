#!/usr/bin/env bash
# Tokyo Night clipboard history picker for Niri + wofi + cliphist.
# Shows real thumbnails for binary image entries.

set -u

notify() {
    notify-send -a "Clipboard" "$1" "${2:-}" 2>/dev/null || true
}

# Debug/testing: copy a specific cliphist ID without opening the picker.
if [ "${1:-}" = "--copy-id" ] && [ -n "${2:-}" ]; then
    cliphist decode "$2" | wl-copy
    exit 0
fi

list=$(cliphist -preview-width 60 list 2>/dev/null)
if [ -z "$list" ]; then
    notify "Clipboard history is empty"
    exit 0
fi

tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/cliphist-wofi.XXXXXX") || exit 1
trap 'rm -rf "$tmpdir"' EXIT

lines=""
declare -A choice_id=()
declare -A choice_is_image=()

while IFS= read -r line; do
    [ -n "$line" ] || continue
    id=${line%%$'\t'*}
    content=${line#*$'\t'}
    display="$line"
    is_image=0

    if [[ "$content" =~ ^\[\[\ binary.*[[:space:]](png|jpg|jpeg|bmp|webp|gif)([[:space:]]|$) ]]; then
        ext=${BASH_REMATCH[1]}
        path="$tmpdir/$id.$ext"
        if cliphist decode "$id" > "$path" 2>/dev/null && [ -s "$path" ]; then
            display="img:$path:text:$line"
            is_image=1
        fi
    fi

    lines+="$display"$'\n'
    choice_id["$display"]="$id"
    choice_is_image["$display"]="$is_image"
done <<< "$list"

choice=$(printf '%s' "$lines" |
    wofi --dmenu --allow-images --image-size 24 --parse-search --prompt "Clipboard" --insensitive 2>/dev/null) || exit 0
[ -n "$choice" ] || exit 0

if [[ "$choice" == img:*:text:* ]]; then
    entry=${choice#*:text:}
else
    entry=$choice
fi

id=${choice_id[$choice]:-}
[ -n "$id" ] || id=$(printf '%s' "$entry" | cut -f1)
[ -n "$id" ] || exit 0

if [ "${choice_is_image[$choice]:-0}" = "1" ] || [[ "$entry" == *"[[ binary data"* ]]; then
    cliphist decode "$id" | wl-copy
    notify "Copied image" "Image from clipboard history"
else
    cliphist decode "$id" | wl-copy
    preview=$(printf '%s' "${entry#*$'\t'}" | head -c 80)
    notify "Copied to clipboard" "$preview"
fi
