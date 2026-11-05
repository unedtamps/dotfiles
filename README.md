# dotfiles

Personal Linux dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each top-level directory is a Stow package mirroring its target path under `~`:

```
.
├── configs/     .config/{nvim,kitty,opencode,niri,waybar-niri,mako,wofi,swaylock,qt6ct,fontconfig,btop,yazi,tmux}
└── zsh/         .zshrc
```

## Installation

```sh
cd ~/.dotfiles
stow configs zsh
```

This symlinks all config files to their proper locations under `~`.

To install only a specific category:

```sh
stow configs   # everything under .config
stow zsh       # Zsh
```

## Theme — Tokyo Night (Night)

The desktop is themed around the Tokyo Night palette (`bg #1a1b26`, `fg #c0caf5`, `blue #7aa2f7`, ...):

- **Compositor**: niri — gaps 8, 2px border (blue active / overlay inactive), 12px rounded corners, soft shadow, xray blur (`background-effect`) on kitty, waybar, wofi and mako
- **Wallpaper**: `awww-daemon` with a fade transition (`~/Pictures/Wallpaper/riced/`)
- **Bar**: waybar floating pill (`waybar-niri/`)
- **GTK**: adw-gtk3-dark + Papirus-Dark + Noto Sans (set via gsettings)
- **Qt**: qt6ct with a Tokyo Night Fusion palette (`QT_QPA_PLATFORMTHEME=qt6ct` via niri `environment`)
- **Fonts**: JetBrainsMono Nerd Font (mono, incl. fontconfig aliases) + Noto Sans (UI)

Extra packages the theme expects (Arch):

```sh
sudo pacman -S --needed adw-gtk-theme papirus-icon-theme qt6ct
```

## Per-config READMEs

- [Neovim](configs/.config/nvim/)
- [Kitty](configs/.config/kitty/)
- [Niri](configs/.config/niri/)

## Secret scanning

A pre-commit hook runs [gitleaks](https://github.com/gitleaks/gitleaks) against
staged changes and blocks commits containing secrets. Enable it once per clone:

```sh
git config core.hooksPath .githooks
```

Install gitleaks (Arch: `sudo pacman -S gitleaks`, or put the binary in
`~/.local/bin`). The hook falls back to `~/.local/bin/gitleaks` automatically.
