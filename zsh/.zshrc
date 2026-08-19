# ~/.zshrc — managed by ~/dotfiles (stow package: zsh)
# Machine-specific bits go in ~/.zshrc.local, secrets in ~/.secrets (both untracked).

# ---------------------------------------------------------------------------
# PATH basics (Homebrew on macOS / Linuxbrew, ~/.local/bin, ~/bin, ~/scripts)
# ---------------------------------------------------------------------------
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
export PATH="$HOME/.local/bin:$HOME/bin:$HOME/scripts:/usr/local/bin:$PATH"
[ -d "$HOME/.deno/bin" ] && export PATH="$HOME/.deno/bin:$PATH"

# Load local secrets (untracked, chmod 600). Put API keys etc. in ~/.secrets.
[ -f "$HOME/.secrets" ] && source "$HOME/.secrets"

# ---------------------------------------------------------------------------
# oh-my-zsh
# ---------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Keep OMZ from nagging / auto-updating in automation shells.
zstyle ':omz:update' mode reminder

# Plugins. zsh-autosuggestions, zsh-syntax-highlighting and zsh-nvm live in
# $ZSH_CUSTOM/plugins (install.sh clones them). zsh-nvm installs nvm itself.
plugins=(
  git
  zsh-autosuggestions
  vi-mode
  zsh-nvm
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ---------------------------------------------------------------------------
# vi mode
# ---------------------------------------------------------------------------
bindkey -v
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true
MODE_INDICATOR="%F{yellow}+%f"

# Ctrl-F: fuzzy project finder -> tmux session
bindkey -s ^f "tmux-sessionizer\n"

# ---------------------------------------------------------------------------
# nvm: auto-switch node version on cd when a .nvmrc is present
# (place after nvm initialisation — zsh-nvm does that above)
# ---------------------------------------------------------------------------
if command -v nvm >/dev/null 2>&1; then
  autoload -U add-zsh-hook
  load-nvmrc() {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use
      fi
    elif [ "$node_version" != "$(nvm version default)" ]; then
      echo "Reverting to nvm default version"
      nvm use default
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi

# ---------------------------------------------------------------------------
# Editor
# ---------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
# remap vim to nvim
alias vim="nvim"
alias vi="nvim"
alias oldvim="command vim"
alias pn="pnpm"
alias lg="lazygit"

# easy access to my config files
alias zshconfig="nvim $HOME/.zshrc"
alias zconf="nvim $HOME/.zshrc"
alias dotfiles="cd $HOME/dotfiles"

alias av="ansible-vault"

# command shortcuts
alias sr="omz reload"
alias cleanbr="git branch | grep -ve \" release/*\" | xargs git branch -D"

# i360 (macOS desktop app log)
alias alog="tail -f ~/Library/Application\ Support/i360/tradeit-221003/logs/arthos.log"

# Claude Code usage dashboard (lives in ~/scripts on the laptop — only alias if present)
[ -x "$HOME/scripts/claude-usage.sh" ] && alias claude-usage="$HOME/scripts/claude-usage.sh"
[ -x "$HOME/scripts/claude-usage-obsidian.sh" ] && alias claude-usage-update="$HOME/scripts/claude-usage-obsidian.sh"

# ---------------------------------------------------------------------------
# Machine-local overrides (untracked): extra PATH entries, aliases like
# `orc`, tool hooks appended by installers, etc.
# ---------------------------------------------------------------------------
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
