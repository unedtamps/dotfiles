# dotfiles

Personal Linux dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```
.
├── cli/         Zsh, tmux, yazi
├── editors/     Neovim
└── gui/         Kitty
```

## Installation

```sh
cd ~/.dotfiles
stow cli editors gui
```

This symlinks all config files to their proper locations under `~`.

To install only a specific category:

```sh
stow cli      # Zsh, tmux, yazi
stow editors  # Neovim
stow gui      # Kitty
```

## Per-config READMEs

- [CLI tools](cli/)
- [Tmux](cli/.config/tmux/)
- [Yazi](cli/.config/yazi/)
- [Neovim](editors/.config/nvim/)
- [Kitty](gui/.config/kitty/)
