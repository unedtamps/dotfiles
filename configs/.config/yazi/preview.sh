#!/usr/bin/env bash
# Preview helper for fzf: text, images, PDFs, video, archives, directories.
set -u

f=${1:-}
[ -n "$f" ] && [ -e "$f" ] || exit 0

cols=${FZF_PREVIEW_COLUMNS:-60}
lines=${FZF_PREVIEW_LINES:-30}
size="${cols}x${lines}"

# Prefer Kitty's graphics protocol: fzf 0.74+ can display real images in its
# preview window via Unicode placeholders, so this is full resolution instead
# of text cells. Fall back to timg/chafa on terminals without Kitty graphics.
img_preview() {
	if [ -n "${KITTY_WINDOW_ID:-}" ] && command -v kitten >/dev/null 2>&1; then
		kitten icat \
			--clear \
			--transfer-mode=memory \
			--unicode-placeholder \
			--stdin=no \
			--loop=1 \
			--place="${cols}x${lines}@0x0" \
			"$1" |
			sed '$d' | sed $'$s/$/\033[m/'
	elif command -v timg >/dev/null 2>&1; then
		# Quarter blocks give 2x2 pixels per cell; -a avoids soft downscaling.
		timg --pixelation=quarter -a --frames=1 -g "$size" -- "$1" 2>/dev/null
	elif command -v chafa >/dev/null 2>&1; then
		chafa -f symbols -c 256 -s "$size" -- "$1" 2>/dev/null
	fi
}

if [ -d "$f" ]; then
	eza --color=always --tree --level=2 --icons=always -- "$f"
	exit 0
fi

mime=$(file --mime-type -b -- "$f" 2>/dev/null || true)
case "$mime" in
image/*)
	img_preview "$f"
	;;
application/pdf)
	tmp=$(mktemp -d)
	if pdftoppm -f 1 -l 1 -singlefile -png -r 72 -- "$f" "$tmp/page" >/dev/null 2>&1; then
		img_preview "$tmp/page.png"
	fi
	rm -rf "$tmp"
	;;
video/*)
	tmp=$(mktemp -d)
	if ! ffmpeg -v error -ss 1 -i "$f" -frames:v 1 -y "$tmp/frame.png" >/dev/null 2>&1 ||
		[ ! -s "$tmp/frame.png" ]; then
		ffmpeg -v error -ss 0 -i "$f" -frames:v 1 -y "$tmp/frame.png" >/dev/null 2>&1
	fi
	[ -s "$tmp/frame.png" ] && img_preview "$tmp/frame.png"
	rm -rf "$tmp"
	;;
application/zip | application/x-7z-compressed | application/x-tar | application/gzip | application/x-compressed-tar)
	7z l -- "$f" 2>/dev/null | head -n "$lines"
	;;
*)
	bat --color=always --paging=never --style=numbers --line-range=":$lines" -- "$f" 2>/dev/null ||
		sed -n "1,${lines}p" -- "$f"
	;;
esac
