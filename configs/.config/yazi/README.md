# Yazi Config

File manager configuration with custom keybinds, theme, and plugins.

## Plugins

- [git.yazi](plugins/git.yazi/) – Git status indicators
- [fzf-plus.yazi](plugins/fzf-plus.yazi/) – fzf picker with a custom candidate command (`Z` searches from `$HOME`)

## Fuzzy picker previews

`z` (current directory, prompt `cwd>`) and `Z` (`$HOME`, prompt `home>`) open fzf
with a preview pane. The `home>` prompt is the quickest way to confirm which
root is active. `Z` searches all of `$HOME`, so files under the current
directory still appear when the current directory is inside `$HOME`.

`fzf-plus` has a small local patch adding `--fzf-opts`, `--preview`, and
`--vim-keys`; keep that in mind if you upgrade or reinstall the plugin. The
preview is enabled by the keymap itself, so it works however Yazi is launched.

The picker is modal:

- **INSERT** (default): typing filters; `Esc` switches to NORMAL
- **NORMAL** (`NORMAL cwd>` / `NORMAL home>`): `h`/`l` move in the query,
  `j`/`k` move the list, `i` returns to INSERT, `Esc` closes fzf
- letters and digits are ignored in NORMAL so they don't accidentally filter

- text/code – `bat`
- images, PDFs, video – `kitten icat` (full-resolution Kitty graphics), falling
  back to `timg` quarter-blocks and then `chafa` on other terminals
- archives – `7z l`
- directories – `eza --tree`

Requires: `fzf`, `fd`, `bat`, `eza`, `file`, `ffmpeg`, `pdftoppm`, `7z`, and
one image renderer: `kitten` (Kitty, best quality), `timg`, or `chafa`.

## Key bindings

See [keymap.toml](keymap.toml) for the full set of custom keybindings.
