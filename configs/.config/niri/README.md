# Niri + Kitty transparency notes

## 2026-11-03 — transparent kitty looked solid

### Symptom

- Kitty had `background_opacity 0.55`.
- Niri had `background-effect { xray true; blur true; }`.
- The terminal still looked like a flat Tokyo Night / blue rectangle — no wallpaper visible.

### Root cause

Niri draws the border/focus ring as a **solid background rectangle behind windows** by default. A transparent window composites over that rectangle instead of the wallpaper.

`prefer-no-csd` alone did **not** fix kitty, because kitty still did not opt into server-side decorations.

### Fix

In `config.kdl`:

```kdl
window-rule {
    match app-id="kitty"
    draw-border-with-background false

    background-effect {
        xray true
        blur true
        noise 0.03
    }
}
```

### Other changes that matter

- `xray true` is the reliable, cheap blur mode. `xray false` is experimental and can disappear during open/close animations.
- `background_opacity 0.55` gives a visible glass effect; `0.78` is nearly opaque.
- Scope `background-effect` to kitty and specific layer surfaces. Applying it to every window is wasted GPU work.
- OpenCode's TUI can paint its own background. Test the blur in a plain shell (`Mod+T`) before assuming the compositor is broken.
- The wallpaper is dark and fairly uniform, so even a correct blur looks subtle. A brighter or more colorful wallpaper makes the effect obvious.

### How this was diagnosed

1. `niri msg windows` confirmed the app-id was `kitty`.
2. `journalctl --user -u niri -b | grep -i config` confirmed config reloads.
3. `grim -o eDP-1 /tmp/shot.png` captured the screen.
4. ImageMagick sampled pixels: the terminal interior was the border color blended with the terminal, not the wallpaper average.
5. Disabling blur and lowering opacity made the tint lighter, proving the window was compositing over a solid colored rectangle rather than the wallpaper.
6. Adding `draw-border-with-background false` made the blurred wallpaper visible.

### Quick verification

```bash
niri validate
niri msg windows | grep -A2 kitty
grim -o eDP-1 /tmp/niri-check.png
magick /tmp/niri-check.png -crop 1x1+800+500 txt:-
```

If the sampled color is close to the wallpaper behind the terminal, transparency is working.

### Useful commands

```bash
# What is actually running?
niri msg windows

# Did Niri reload the config?
journalctl --user -u niri -b --no-pager | grep -i config

# Capture the current screen
grim -o eDP-1 /tmp/shot.png

# Average color of a wallpaper
magick wallpaper.jpg -resize 1x1 txt:-
```
