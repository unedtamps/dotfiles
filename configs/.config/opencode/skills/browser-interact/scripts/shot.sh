#!/usr/bin/env bash
# Capture the screen with Spectacle and print the resulting path and size.
#
# Usage: shot.sh [--window|--full|--monitor|--region] [slug]
#   --window   active window (default) - raise it first with focus-window.sh
#   --full     every screen
#   --monitor  current monitor
#   --region   interactive selection (needs a human at the keyboard)
#
# Output: /tmp/opencode/<slug>-<timestamp>.png

set -euo pipefail

mode="${1:---window}"
slug="${2:-shot}"
out_dir="${OUT_DIR:-/tmp/opencode}"

case "$mode" in
  --window)  args=(-a) ;;
  --full)    args=(-f) ;;
  --monitor) args=(-m) ;;
  --region)  args=(-r) ;;
  -h|--help)
    sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *)
    echo "shot.sh: unknown mode '$mode' (want --window, --full, --monitor or --region)" >&2
    exit 2
    ;;
esac

mkdir -p "$out_dir"
out="$out_dir/${slug}-$(date +%Y%m%d-%H%M%S).png"

if ! command -v spectacle >/dev/null 2>&1; then
  echo "shot.sh: spectacle not found" >&2
  exit 1
fi

# -b background, -n no notification, -o output file
if ! timeout 30 spectacle -b -n "${args[@]}" -o "$out"; then
  echo "shot.sh: capture failed" >&2
  exit 1
fi

if [ ! -s "$out" ]; then
  echo "shot.sh: capture produced no file" >&2
  exit 1
fi

if command -v identify >/dev/null 2>&1; then
  printf '%s %s\n' "$out" "$(identify -format '%wx%h' "$out" 2>/dev/null || echo '')"
else
  printf '%s\n' "$out"
fi

echo "shot.sh: now read the PNG before drawing any conclusion" >&2
