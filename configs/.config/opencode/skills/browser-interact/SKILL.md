---
name: browser-interact
description: Open a local web app in a browser, look at it, click through it, type into it, and capture screenshots on this KDE/Wayland machine. Use whenever frontend work needs the running page instead of the source — "open it in the browser", "screenshot localhost:3000", "check the UI", "does the layout render", "click through the flow", "fill in the login form", "verify my CSS change". Drives Firefox and Chrome through the open-computer-use MCP, types with xdotool, raises windows via KWin over D-Bus, and captures with Spectacle, and documents exactly which input paths work here.
---

# Browser Interact

Drive a real browser on this desktop, see what it renders, and click through the app.

The point is **eyes plus a mouse**: screenshots prove what the page looks like, accessibility-tree reads prove what the page *says*, and element clicks prove the app responds. Do not use this as a replacement for tests or for reading code.

## Quick start

```bash
S=~/.config/opencode/skills/browser-interact/scripts
curl -sS -o /dev/null -w '%{http_code}\n' --max-time 3 http://127.0.0.1:7456   # server up?
MOZ_ENABLE_WAYLAND=0 nohup firefox --new-window "http://127.0.0.1:7456" >/tmp/firefox.log 2>&1 &  # X11, so typing works
$S/focus-window.sh <title-fragment>                                           # e.g. the page name, not "firefox"
$S/shot.sh --window home                                                       # capture
printf '%s' 'hello' | $S/type-text.sh <title-fragment>                            # type, if needed
```

Then `read` the printed PNG path, and only after that start clicking. The app name for the MCP tools is `Firefox` (or `Google Chrome`); get it from `list_apps`, not from guesswork.

## Verified capability matrix

Measured on this machine on 2026-11-02 with Firefox 157 and Chrome 156, KDE Plasma on Wayland. Re-verify before trusting it after a version bump.

| Capability | Status | Notes |
|---|---|---|
| `get_app_state` (AX tree) | works | Firefox exposes full web content. Chrome needs `--force-renderer-accessibility`. |
| `click` by `element_index` | **works** | The reliable input path. Opened tabs, switched tabs, selected chips. |
| `perform_secondary_action` | works | Used `switch` on a page tab. |
| `click` by `x,y` | partial | Requires a screenshot in the same turn; see "Coordinate clicks". |
| `type_text` in browser web content | **broken** | No effect in Firefox or Chrome. |
| `press_key` in browser | **broken** | `ctrl+l`, `ctrl+t`, `Return`, `Tab` all no-ops. |
| `set_value` on browser fields | **broken** | Fails with "Cannot set a value for an element that is not settable". |
| `type_text` in native Qt apps | works | Verified in KRunner; the MCP is fine, the browsers ignore synthetic keys. |
| **`scripts/type-text.sh` (xdotool)** | **works** | Types into X11/XWayland windows - the only working text entry into a browser. One-time KDE permission prompt. |
| Spectacle capture | works | Window, monitor and full-screen modes. |

> The MCP types through AT-SPI `EditableText` / synthetic keys. Firefox and Chromium do not accept those in their web content, which is why `type_text` does nothing there. Use `scripts/type-text.sh` (xdotool over XTest) for real keystrokes.

## Environment facts

- KDE Plasma, Wayland session, `DISPLAY=:1` via XWayland, screen 1707x1067 at 1.5x scale.
- Available: `spectacle`, `import`, `xclip`, `xsel`, `qdbus6`, `xdotool`.
- Not available: `wmctrl`, `kdotool`, `grim`, `scrot`, `wtype`, `ydotool`, `gnome-screenshot`.
- Firefox `WM_CLASS` is `firefox`. Chrome's is `google-chrome`.
- **Two kinds of window.** xdotool only sees X11/XWayland clients. Wayland-native clients are invisible to it — no `search`, no `type`, no `windowactivate`. The MCP's element clicks work on both; xdotool is the better tool for X11.
- **Scaling trap:** Spectacle PNGs come out at device pixels (about 1.5x), while `get_app_state` frame coordinates are logical. Never mix the two in coordinate math.
- **The OpenCode window overlaps the browser.** It is the usual cause of "the screenshot is of the wrong thing" and "my click did nothing".

## The loop

1. Confirm the dev server answers.
2. Launch the browser at the URL.
3. Raise and verify the window.
4. Read state (`get_app_state`).
5. Do exactly one action.
6. Read state again.
7. Capture a screenshot and actually look at the PNG.

### 1. Confirm the server

```bash
curl -sS -o /dev/null -w '%{http_code}\n' --max-time 3 http://127.0.0.1:7456
```

Anything other than `200`/`3xx` means the app is not up; fix that first.

### 2. Launch

```bash
nohup firefox --new-window "http://127.0.0.1:7456" >/tmp/firefox.log 2>&1 &
```

Firefox is the better target here: its accessibility tree exposes the page's headings, buttons, tabs and inputs, which is what makes `click` by index possible.

**If you need to type into the page**, launch it as an X11 client so xdotool can reach it:

```bash
MOZ_ENABLE_WAYLAND=0 nohup firefox --new-window "http://127.0.0.1:7456" >/tmp/firefox.log 2>&1 &
```

A Wayland-native Firefox still screenshots and still accepts MCP element clicks, but `type-text.sh` cannot see it. Check which kind you have with `xdotool search --onlyvisible --class firefox` — an empty result means Wayland-native.

Chrome only exposes web content when forced:

```bash
nohup google-chrome-stable --force-renderer-accessibility --new-window "http://127.0.0.1:7456" >/tmp/chrome.log 2>&1 &
```

If Firefox already has a window, `--new-window` may reuse the session and add a tab instead. Check with `list_apps`, then confirm which document actually has the URL in the AX tree.

### 3. Raise and verify

The browser is behind the terminal more often than not, and both screenshots and clicks follow the *active* window. Use the bundled script:

```bash
~/.config/opencode/skills/browser-interact/scripts/focus-window.sh <title-fragment>
```

Pass something that identifies **one** window — a page title fragment like `opendesign`, not just `firefox`, because every Firefox window matches `firefox`. The script refuses to guess when several match and lists the candidates instead.

It tries xdotool first (`xdotool windowactivate --sync`), then falls back to KWin scripting over D-Bus (`org.kde.kwin.Scripting.loadScript` then `.start`) which also covers Wayland-native windows. It prints `ACTIVATED <caption>` plus which path it used.

For the KWin path, verify through the journal:

```bash
journalctl --user --since "10 seconds ago" | grep "focus-window:"
```

The script prints `ACTIVATED <caption>`, `NOT_FOUND <pattern>` (exit 1), or `MULTI n :: ...` (exit 2) when ambiguous.

If you need it inline, the script body is small: find the window in `workspace.windowList()`, set `w.minimized = false`, assign `workspace.activeWindow = w`, and `print()` the caption for the journal.

### 4. Read state

```
get_app_state({ app: "Firefox" })
```

Scan for the address bar value, the `page tab` entries, and the `document web <Title>` node. That tells you whether the URL you asked for is actually loaded. `include_screenshot: false` is fine and much cheaper; the AX tree is the part you reason about.

This call is also a precondition: action tools refuse to run until the app has been read at least once in the current turn ("No app state is available ... Run get_app_state before action tools"). The dumps are large, so filter them in code rather than pasting the whole tree into the conversation.

### 5. Act — one click

```
click({ app: "Firefox", element_index: "167", click_method: "accessibility" })
```

Prefer `click_method: "accessibility"` with an element index. That issues a real AT-SPI action inside the app and is the only input path that worked consistently.

### 6. Read again

Element indexes are **snapshots, not handles**. Any DOM change, tab switch or navigation renumbers them. Re-read before the next action. Clicking a stale index either fails ("could not click the requested element") or hits the wrong thing.

`include_ax: false` also invalidates every index — it is documented on the tool, and it is easy to get wrong.

### 7. Capture and look

```bash
spectacle -b -n -a -o /tmp/opencode/shot.png
```

Then `read` the PNG. Saving a screenshot without reading it proves nothing; describe what is on screen before claiming the UI is correct.

## Coordinate clicks

Coordinates work, but the MCP enforces a precondition:

- You must request a screenshot in the same turn (`get_app_state` with `include_screenshot: true`), otherwise it refuses with *"request a screenshot before screenshot-coordinate actions"*.
- `click_method: "global"` additionally needs `OPEN_COMPUTER_USE_ALLOW_GLOBAL_POINTER_FALLBACKS=1` in the MCP server's environment. Without it you get an explicit error. Plain `click({x, y})` is accepted, but landing accuracy depends on the scale calibration, which was not confirmed in the test run.
- Remember the 1.5x scale mismatch described above; calibrate by clicking something harmless and confirming the visible result.

Use coordinates only for canvas, charts, sliders and drag targets that have no accessibility node.

## Text entry

The MCP cannot type into a browser. xdotool can, because it goes through XTest rather than AT-SPI. Use the wrapper:

```bash
S=~/.config/opencode/skills/browser-interact/scripts
$S/focus-window.sh <title-fragment>
printf '%s' 'hello from the agent' | $S/type-text.sh <title-fragment>
```

`type-text.sh` reads from stdin (so secrets stay out of `ps`), refuses to type unless the active window matches the pattern you give it, and prints a clear error when the window is Wayland-native. Add `--enter` only when you mean to submit.

**First run needs a human.** KDE pops a *Remote Control* dialog — "xdotool is asking to control input devices" — the first time xdotool injects input. That dialog is a Wayland-native KWin surface: it is not in `list_apps`, xdotool cannot see it, and nothing you have can click it. Input sent while it is open is **silently dropped** (xdotool still exits 0). Ask the user to press **Allow** and tick *"Always allow apps claiming to be xdotool"*, then retry. There is no CLI way to pre-approve it.

Clearing a field afterwards: `xdotool key --clearmodifiers ctrl+a BackSpace`. General shortcuts are the same route: `xdotool key ctrl+l` for the address bar, `ctrl+r` to reload, `F11` for fullscreen. Confirm the effect in a screenshot; keys that silently miss are the usual failure here.

When xdotool is not the answer, in order:

1. **Avoid typing.** Put the value in the URL (query string, hash route, deep link) and launch or navigate to it. Most "I need to type" cases are really "I need the app in a given state".
2. **Use the app's own affordances.** If it is your code, add a dev-only seed, magic-link route or pre-filled fixture. For auth, a local test account with an auto-login route beats typing.
3. **Clipboard + middle click** (unverified): `printf '%s' 'text' | xclip -selection primary -i`, then a middle-click in the field. X11 apps paste `PRIMARY` on middle click. It did not paste in the one test run here, so treat it as a hypothesis.
4. **`wtype`** for Wayland-native windows — not installed, would need `apt install wtype`.
5. **Scripted automation.** Playwright/CDP if the project already has it. That is the right answer when a flow needs many keystrokes and assertions.

## Screenshot recipes

| Goal | Command |
|---|---|
| Active window only | `spectacle -b -n -a -o /tmp/opencode/shot.png` |
| Whole monitor | `spectacle -b -n -m -o /tmp/opencode/shot.png` |
| All screens | `spectacle -b -n -f -o /tmp/opencode/shot.png` |
| Delayed (menus, tooltips) | `spectacle -b -n -a -d 3 -o /tmp/opencode/shot.png` |
| Interactive region | `spectacle -b -n -r -o /tmp/opencode/shot.png` (needs a human) |

`-b` background, `-n` no notification, `-o` output path. Always write to `/tmp/opencode` so nothing lands in the repo.

For a clean hero shot of the app without browser chrome, drop fullscreen first: `xdotool key --clearmodifiers F11`, capture, then press it again to restore.

One file per state, never overwrite: `shot-before.png`, `shot-after-click.png`. You need both to compare.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| "Run get_app_state before action tools" | Action called first in the turn | Read state, then act |
| Screenshot is the terminal | The browser is not the active window | `~/.config/opencode/skills/browser-interact/scripts/focus-window.sh <title-fragment>`, then capture |
| Click does nothing | Stale element index | Re-read `get_app_state`, retry with the new index |
| "could not click the requested element" | Node has no click action (e.g. `page tab`) | Use `perform_secondary_action` with `switch` |
| "requires OPEN_COMPUTER_USE_ALLOW_GLOBAL_POINTER_FALLBACKS=1" | Global pointer path disabled | Use element clicks, or set the env var in `opencode.json` and restart |
| "Cannot set a value..." | Field is not settable via AT-SPI | Do not use `set_value` on browser fields |
| Typing does nothing | Browsers ignore synthetic AT-SPI keys | Use `scripts/type-text.sh`, not `type_text` |
| KDE "Remote Control" dialog appears | First xdotool input injection | Human clicks **Allow** (tick *Always allow*); retry, since input sent meanwhile was dropped |
| `type-text.sh`: "no X11 active window" | Target is Wayland-native | Relaunch with `MOZ_ENABLE_WAYLAND=0`, or use `wtype` |
| `type-text.sh`: "refusing to type" | Wrong window has focus | `focus-window.sh <pattern>`, then retry |
| Typed text lands in the terminal | Focus check bypassed with `--no-check` | Drop `--no-check`; it exists for this reason |
| Blank page in the shot | Dev server still compiling | Wait, re-check `curl`, capture again |
| Chrome tree is empty | Renderer accessibility off | Relaunch with `--force-renderer-accessibility` |
| Focus script does nothing | No window matched the pattern | Check `list_apps`; match on caption or `WM_CLASS` |

Never `pkill -f google-chrome`: the pattern matches your own shell command line and kills the session. Use `pkill -x chrome` or `pkill -x firefox`.

## Authenticated testing

Typing is possible, but only through `type-text.sh` and only into an X11 window. That is enough to log in with a local test account — with the guardrails below.

- **Allowed:** local/staging test accounts, seeded dev users, cookie or token injection done by the app itself, testing behind an existing session in the profile.
- **Never in this repo:** `~/.dotfiles` is git-tracked. Credentials do not belong in this skill, in `AGENTS.md`, or in any committed file.
- **Keep secrets out of argv.** `type-text.sh` reads stdin precisely so the value does not appear in `ps`. Never `xdotool type "$PASSWORD"` directly.
- **The transcript is part of the blast radius.** Anything typed is in the conversation and possibly in the AX dump. Use a disposable test account and rotate it afterwards.
- **Profile isolation**, when the test should not touch real state:
  ```bash
  MOZ_ENABLE_WAYLAND=0 firefox --new-instance --profile /tmp/opencode/ff-test-profile --new-window "http://127.0.0.1:7456"
  ```
- Use the real profile only when the point is to test with an existing session. That profile holds saved passwords and cookies; do not browse to personal pages with it.
- While logged in: navigate, click, log out. Do not change password, email, billing, or delete anything without being asked explicitly.
- Screenshots of authenticated pages go to `/tmp/opencode` and get deleted after the run.

## Artifacts and cleanup

- Screenshots: `/tmp/opencode/<slug>-<state>.png`, one per state.
- Logs: `/tmp/firefox.log`, `/tmp/chrome.log`.
- Leave the browser open if the user may want to look; close it when it was purely a test artifact.
- Delete authenticated screenshots and the throwaway profile when done: `rm -rf /tmp/opencode/ff-test-profile`.

## Scripts

Both live in `~/.config/opencode/skills/browser-interact/scripts/` (symlinked from `~/.dotfiles`).

- `focus-window.sh [pattern]` — raise a window. Tries xdotool first (X11 only), falls back to KWin scripting (any window), and says which path it used.
- `shot.sh [--window|--full|--monitor|--region] [slug]` — capture to `/tmp/opencode` and print the path plus its pixel size.
- `type-text.sh [pattern] [--enter] [--no-check]` — type stdin into the focused X11 window via xdotool, refusing if the active window does not match the pattern.
