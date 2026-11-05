#!/usr/bin/env bash
# Type text into the focused X11 window with xdotool.
#
# This exists because the open-computer-use MCP cannot type into browser
# content: it sends AT-SPI synthetic keys, which Firefox and Chromium ignore.
# xdotool goes through XTest instead, so it works - but only for X11/XWayland
# windows, and only when the window already has keyboard focus.
#
# Text is read from stdin, never argv, so credentials do not show up in `ps`.
#
# Usage:
#   printf '%s' "$SECRET" | type-text.sh <window-pattern> [--enter]
#   printf '%s' "hello" | type-text.sh --no-check
#
#   <window-pattern>  case-insensitive substring of the active window's name or
#                     WM_CLASS. Acts as a safety check: if it does not match,
#                     nothing is typed.
#   --enter           press Return after typing (submits forms - use knowingly)
#   --no-check        skip the focus check (only when you know what is focused)
#
# Environment:
#   TYPE_DELAY        per-character delay in ms (default 40)

set -euo pipefail

pattern=""
press_enter=0
check=1

while [ $# -gt 0 ]; do
  case "$1" in
    --enter)    press_enter=1; shift ;;
    --no-check) check=0; shift ;;
    -h|--help)
      sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    -*) echo "type-text.sh: unknown option '$1'" >&2; exit 2 ;;
    *)
      if [ -n "$pattern" ]; then
        echo "type-text.sh: only one window pattern allowed" >&2
        exit 2
      fi
      pattern="$1"; shift
      ;;
  esac
done

if ! command -v xdotool >/dev/null 2>&1; then
  echo "type-text.sh: xdotool is not installed" >&2
  exit 1
fi

if [ "$check" -eq 1 ]; then
  if [ -z "$pattern" ]; then
    echo "type-text.sh: pass a window pattern to verify focus, or --no-check" >&2
    exit 2
  fi

  active_id="$(xdotool getactivewindow 2>/dev/null || true)"
  if [ -z "$active_id" ]; then
    echo "type-text.sh: no X11 active window - the target is probably Wayland-native." >&2
    echo "type-text.sh: xdotool cannot reach it. Relaunch with MOZ_ENABLE_WAYLAND=0," >&2
    echo "type-text.sh: or use a Wayland-native tool such as wtype." >&2
    exit 1
  fi

  active_name="$(xdotool getwindowname "$active_id" 2>/dev/null || true)"
  active_class="$(xprop -id "$active_id" WM_CLASS 2>/dev/null | sed 's/.*WM_CLASS(STRING) = //; s/"//g' || true)"

  haystack="$(printf '%s %s' "$active_name" "$active_class" | tr '[:upper:]' '[:lower:]')"
  needle="$(printf '%s' "$pattern" | tr '[:upper:]' '[:lower:]')"

  case "$haystack" in
    *"$needle"*) ;;
    *)
      echo "type-text.sh: refusing to type." >&2
      echo "type-text.sh:   active window: '${active_name}' [${active_class}]" >&2
      echo "type-text.sh:   wanted pattern: '${pattern}'" >&2
      echo "type-text.sh: raise the right window first (scripts/focus-window.sh)." >&2
      exit 1
      ;;
  esac
fi

text="$(cat)"
if [ -z "$text" ]; then
  echo "type-text.sh: empty input on stdin" >&2
  exit 1
fi

xdotool type --clearmodifiers --delay "${TYPE_DELAY:-40}" -- "$text"

if [ "$press_enter" -eq 1 ]; then
  sleep 0.2
  xdotool key --clearmodifiers Return
fi
