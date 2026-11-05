#!/usr/bin/env bash
# Raise a window on this KDE/Wayland desktop.
#
# Two paths, because the desktop has two kinds of client:
#   1. xdotool        - fast, works for X11/XWayland windows only
#   2. KWin scripting - works for every window, including Wayland-native ones
#
# The pattern must identify *one* window. "firefox" is a bad pattern when more
# than one Firefox window is open; pass a fragment of the page title instead,
# e.g. "opendesign". Ambiguity is an error here on purpose: activating the
# wrong window is worse than failing.
#
# Usage: focus-window.sh [pattern]
#   pattern  case-insensitive substring matched against WM_CLASS, resource name
#            and window caption. Default: firefox.

set -euo pipefail

pattern="${1:-firefox}"

needle="$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')"

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

window_class() {
  xprop -id "$1" WM_CLASS 2>/dev/null \
    | sed 's/.*WM_CLASS(STRING) = //; s/"//g' \
    || true
}

# ---- path 1: xdotool (X11 clients only) -------------------------------------
if command -v xdotool >/dev/null 2>&1; then
  ids="$(
    { xdotool search --onlyvisible --class "$pattern" 2>/dev/null || true
      xdotool search --onlyvisible --name  "$pattern" 2>/dev/null || true
    } | sort -u
  )"

  candidates=()
  if [ -n "$ids" ]; then
    while read -r id; do
      [ -n "$id" ] || continue
      name="$(xdotool getwindowname "$id" 2>/dev/null || true)"
      [ -n "$name" ] || continue
      hay="$(lower "$name $(window_class "$id")")"
      case "$hay" in
        *"$needle"*) candidates+=("$id|$name") ;;
      esac
    done <<<"$ids"
  fi

  if [ "${#candidates[@]}" -eq 1 ]; then
    id="${candidates[0]%%|*}"
    name="${candidates[0]#*|}"
    if xdotool windowactivate --sync "$id" 2>/dev/null; then
      echo "ACTIVATED $name (xdotool)"
      exit 0
    fi
  elif [ "${#candidates[@]}" -gt 1 ]; then
    echo "focus-window.sh: '$pattern' matches ${#candidates[@]} windows - refusing to guess:" >&2
    for c in "${candidates[@]}"; do
      echo "  - ${c#*|}" >&2
    done
    echo "focus-window.sh: retry with a fragment of the title you want (e.g. the page name)." >&2
    exit 2
  fi
fi

# ---- path 2: KWin scripting (any client, including Wayland-native) ----------
script_dir="$(mktemp -d "${TMPDIR:-/tmp}/focus-window.XXXXXX")"
plugin="focus-window-$$"
script="$script_dir/focus.js"

cleanup() {
  rm -rf "$script_dir"
  qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript "$plugin" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cat >"$script" <<EOF
function matches(w) {
  const rc = ((w.resourceClass || "") + "").toLowerCase();
  const rn = ((w.resourceName || "") + "").toLowerCase();
  const cap = ((w.caption || "") + "").toLowerCase();
  const needle = "$needle";
  return rc.includes(needle) || rn.includes(needle) || cap.includes(needle);
}

const wins = workspace.windowList ? workspace.windowList() : workspace.clientList();
const hits = wins.filter(matches);

if (hits.length === 0) {
  print("focus-window: NOT_FOUND " + "$pattern");
} else if (hits.length > 1) {
  print("focus-window: MULTI " + hits.length + " :: " + hits.map(w => w.caption).join(" | "));
} else {
  const w = hits[0];
  w.minimized = false;
  workspace.activeWindow = w;
  print("focus-window: ACTIVATED " + w.caption);
}
EOF

qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.loadScript "$script" "$plugin" >/dev/null
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.start
sleep 1

result="$(journalctl --user --since "15 seconds ago" 2>/dev/null | grep -F "focus-window:" | tail -1 || true)"
if [ -z "$result" ]; then
  # journald may not be readable in every setup; fall back to a plain hint.
  echo "asked KWin to activate '$pattern' (no journal confirmation available)"
  exit 0
fi

echo "${result#*focus-window: }"

case "$result" in
  *NOT_FOUND*)
    echo "focus-window.sh: no window matched '$pattern' - check the app list first" >&2
    exit 1
    ;;
  *MULTI*)
    echo "focus-window.sh: '$pattern' matches several windows - pass a title fragment instead." >&2
    exit 2
    ;;
esac
