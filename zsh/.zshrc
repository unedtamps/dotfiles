# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
###

# If you come from bash you might have to change your $PATH.
# export PATH=$PATH:$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/share/bcc/tools
export PATH=$PATH:/opt/sonar-scanner/bin:$HOME/go/bin:$HOME/.cargo/bin

# Let Yazi's built-in `z` fzf picker list both files and directories.
# The fzf preview for `z`/`Z` lives in the Yazi config (fzf-plus), not here,
# so it works no matter how Yazi is launched.
export FZF_DEFAULT_OPTS="--walker=file,dir,follow,hidden --walker-skip=.git,node_modules"
# export PATH=$PATH:/usr/share/bcc/tools


export PATH="$HOME/.dotnet/tools:$PATH"

export PATH="$HOME/.linkerd2/bin:$PATH"

export PATH="/home/nedo/.nvm/versions/node/v24.22.1/bin:$PATH"

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"
# POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs)

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="awesomepanda"
export ZSH_THEME="powerlevel10k/powerlevel10k"

function v() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# Interrupt any OpenCode session left running after the TUI exits.
# OpenCode v2's Ctrl+C only closes the TUI; the agent keeps running in the
# background daemon. This cleans up after a normal exit, Ctrl+C, Ctrl+D, /exit.
_opencode_interrupt_active() {
	local reg="${XDG_STATE_HOME:-$HOME/.local/state}/opencode/service.json"
	[[ -r "$reg" ]] || return 0

	local url pass
	url=$(jq -r '.url // empty' "$reg" 2>/dev/null) || return 0
	pass=$(jq -r '.password // empty' "$reg" 2>/dev/null) || return 0
	[[ -n "$url" ]] || return 0

	local active
	active=$(curl -s -m 2 -u "opencode:$pass" "$url/api/session/active" 2>/dev/null | jq -r '.data | keys[]' 2>/dev/null)
	[[ -n "$active" ]] || return 0

	local -A is_active
	local id
	for id in ${(f)active}; do
		is_active[$id]=1
	done

	# Prefer sessions this TUI had open for this directory; otherwise all active.
	local tabs="${reg:h}/latest/tui/tabs.json"
	local ids=""
	if [[ -r "$tabs" ]]; then
		ids=$(jq -r --arg cwd "$PWD" '.cwd[$cwd].tabs[]?.sessionID // empty' "$tabs" 2>/dev/null)
	fi
	[[ -n "$ids" ]] || ids="$active"

	for id in ${(f)ids}; do
		[[ -n "${is_active[$id]:-}" ]] || continue
		curl -s -m 2 -u "opencode:$pass" -X POST "$url/api/session/$id/interrupt" >/dev/null 2>&1
	done
}

# Wrap the TUI only. Subcommands (opencode serve, opencode api, ...) pass through.
opencode() {
	local -a passthrough=(acp api auth debug mcp models plugin reload run serve service session stats uninstall upgrade update mini pair)
	if (( $# > 0 )) && [[ " ${passthrough[*]} " == *" $1 "* ]]; then
		command opencode "$@"
		return $?
	fi

	command opencode "$@"
	local rc=$?
	_opencode_interrupt_active
	return $rc
}


alias vi-lazy="NVIM_APPNAME=LazyVim nvim"
alias vi-astro="NVIM_APPNAME=AstroNvim nvim"

function vis() {
  items=("default" "LazyVim" "AstroNvim")
  config=$(printf "%s\n" "${items[@]}" | fzf --prompt=" Neovim Config  " --height=~50% --layout=reverse --border --exit-0)
  if [[ -z $config ]]; then
    # echo "Nothing selected"
    return 0
  elif [[ $config == "default" ]]; then
    config=""
  fi
  NVIM_APPNAME=$config nvim $@
}

bindkey -s ^a "vis\n"


# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# export PATH="$HOME/.pyenv/bin:$PATH"
# eval "$(pyenv init --path)"
# eval "$(pyenv virtualenv-init -)"


# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
	zsh-autosuggestions
	git
  zsh-syntax-highlighting
  zsh-interactive-cd
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions (also used by OpenCode's
# /editor and Ctrl+X E, git, etc.).
export VISUAL='nvim'
export EDITOR='nvim'
#
# Alias
alias vi="nvim"
alias rust_game="WINIT_UNIX_BACKEND=x11 cargo run"
alias dotfiles='/usr/bin/git --git-dir=$HOME/dotfiles/ --work-tree=$HOME'
alias ls='eza --icons'
alias ll='eza -l --icons'
alias la='eza -la --icons'


eval "$(direnv hook zsh)"

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/nedo/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/nedo/anaconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/nedo/anaconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/nedo/anaconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


. "$HOME/.turso/env"
export PATH=$HOME/.local/bin:$PATH
# source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/nedo/.lmstudio/bin"
# End of LM Studio CLI section

# opencode
export PATH="/home/nedo/.opencode/bin:$PATH"

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pnpm
export PNPM_HOME="/home/nedo/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# Fuzzy-search command history with fzf.
# The selected command is placed on the prompt; press Enter to run it.
cmd() {
  local selected
  selected=$(
    fc -rl 1 |
      awk '{$1=""; sub(/^ /, ""); if ($0 != "") print}' |
      awk '!seen[$0]++' |
      fzf --height 40% --reverse --border --prompt 'cmd> '
  )
  [[ -n "$selected" ]] && print -z -- "$selected"
}
