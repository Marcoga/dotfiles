#!/usr/bin/env bash
# Shared functions for install.sh. Sourced, not executed.
# Requires: DOTFILES exported by the caller.

: "${DOTFILES:?DOTFILES must be set}"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
NVM_VERSION="v0.40.3"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

detect_os() {
  case "$(uname -s)" in
    Darwin) echo macos ;;
    Linux)
      if [[ -r /etc/os-release ]] && grep -qiE 'debian|ubuntu' /etc/os-release; then
        echo linux
      else
        echo linux-unsupported
      fi ;;
    *) echo unknown ;;
  esac
}

# ---------------------------------------------------------------------------
# Guards against the two ways this repo has been broken before.
# ---------------------------------------------------------------------------
preflight_checks() {
  # 1. The repo root must never be stowed as a package ("stow dotfiles" from ~).
  #    Symptom: ~/.local, ~/.config, ~/bin, ~/zsh ... are symlinks into the repo.
  local bad=()
  for d in "$HOME/.local" "$HOME/.config" "$HOME/.local/share" "$HOME/.local/bin"; do
    if [[ -L "$d" ]]; then bad+=("$d -> $(readlink "$d")"); fi
  done
  for d in bin zsh tmux git nvim config launchd install ubuntu skhd yabai; do
    if [[ -L "$HOME/$d" ]] && [[ "$(readlink "$HOME/$d")" == dotfiles/* ]]; then
      bad+=("~/$d -> $(readlink "$HOME/$d")")
    fi
  done
  if [[ ${#bad[@]} -gt 0 ]]; then
    printf '%s\n' "${bad[@]}" >&2
    die "home directory has symlinks from a previous root-level stow. Run bootstrap/migrate-from-rootstow.sh first (dry-run by default)."
  fi

  # 2. Stow must be run with the repo as dir and $HOME as target; we always
  #    pass -d/-t explicitly, but refuse to run from a nested copy of the repo.
  [[ -d "$DOTFILES/zsh" && -d "$DOTFILES/nvim" ]] || die "$DOTFILES does not look like the dotfiles repo"
}

# Real directories must exist BEFORE stowing, otherwise stow "folds" them into
# a single symlink (e.g. ~/.local -> dotfiles/bin/.local) and every tool then
# writes its data inside the git checkout.
ensure_skeleton_dirs() {
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.local/state" \
           "$HOME/.config" "$HOME/.cache"
}

# ---------------------------------------------------------------------------
# Shell
# ---------------------------------------------------------------------------
install_oh_my_zsh() {
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    log "oh-my-zsh already installed"
    return
  fi
  log "installing oh-my-zsh (non-interactive, keeps .zshrc)"
  # KEEP_ZSHRC=yes is what prevents the installer from replacing ~/.zshrc —
  # which, when ~/.zshrc is a stow symlink, overwrites the file in the repo.
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

clone_or_pull() {
  local url="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" pull -q --ff-only || warn "could not update $dest"
  else
    git clone -q --depth 1 "$url" "$dest"
  fi
}

install_zsh_plugins() {
  log "zsh plugins -> $ZSH_CUSTOM_DIR/plugins"
  mkdir -p "$ZSH_CUSTOM_DIR/plugins"
  clone_or_pull https://github.com/zsh-users/zsh-autosuggestions     "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
  clone_or_pull https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
  clone_or_pull https://github.com/lukechilds/zsh-nvm                "$ZSH_CUSTOM_DIR/plugins/zsh-nvm"
}

install_nvm() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    log "nvm already installed in $NVM_DIR"
    return
  fi
  log "installing nvm $NVM_VERSION into $NVM_DIR"
  # PROFILE=/dev/null: do not let the installer append to ~/.zshrc (zsh-nvm loads it).
  PROFILE=/dev/null bash -c "$(curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh)"
  # shellcheck disable=SC1091
  source "$NVM_DIR/nvm.sh"
  if ! nvm ls default >/dev/null 2>&1; then
    log "installing node LTS via nvm"
    nvm install --lts >/dev/null
    nvm alias default 'lts/*' >/dev/null
  fi
}

ensure_default_shell_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh || true)"
  [[ -n "$zsh_path" ]] || { warn "zsh not found; skipping chsh"; return; }
  local current
  if [[ "$(uname -s)" == Darwin ]]; then
    current="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  else
    current="$(getent passwd "$USER" | cut -d: -f7)"
  fi
  if [[ "$current" == *zsh ]]; then return; fi
  log "changing login shell to $zsh_path"
  if ! grep -qx "$zsh_path" /etc/shells 2>/dev/null; then
    echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
  fi
  if sudo -n true 2>/dev/null; then
    sudo chsh -s "$zsh_path" "$USER" || warn "chsh failed — run: chsh -s $zsh_path"
  elif [[ -t 0 ]]; then
    chsh -s "$zsh_path" || warn "chsh failed — run: chsh -s $zsh_path"
  else
    warn "no tty and no passwordless sudo — run manually: chsh -s $zsh_path"
  fi
}

# ---------------------------------------------------------------------------
# Stow
# ---------------------------------------------------------------------------
# Physical path of a (possibly symlinked) directory.
realdir() { (cd "$1" 2>/dev/null && pwd -P) || true; }

# Move real files that would conflict with a package out of the way, and drop
# symlinks left by a previous layout. Never touches anything that already
# resolves into the repo.
backup_conflicts() {
  local pkg="$1"
  # 1. directory-level symlinks (stow folding from an older layout, e.g.
  #    ~/.config/nvim -> ../dotfiles/.config/nvim): remove if dangling or
  #    pointing somewhere other than this package.
  ( cd "$DOTFILES/$pkg" && find . -mindepth 1 -type d ) | sed 's|^\./||' | while read -r rel; do
    local target="$HOME/$rel"
    if [[ -L "$target" ]]; then
      local dest; dest="$(readlink "$target")"
      if [[ ! -e "$target" ]] || [[ "$(realdir "$target")" != "$(realdir "$DOTFILES/$pkg/$rel")" ]]; then
        rm "$target"; warn "removed stale dir symlink $target ($dest)"
      fi
    fi
  done
  # 2. files
  ( cd "$DOTFILES/$pkg" && find . \( -type f -o -type l \) ) | sed 's|^\./||' | while read -r rel; do
    local target="$HOME/$rel"
    local parent; parent="$(realdir "$(dirname "$target")")"
    # parent directory already resolves into the repo -> the file IS the repo file
    [[ -n "$parent" && "$parent" == "$(realdir "$DOTFILES")"/* ]] && continue
    if [[ -L "$target" ]]; then
      local dest; dest="$(readlink "$target")"
      case "$dest" in
        *dotfiles/*|"$DOTFILES"/*) ;;  # ours; stow -R will refresh it
        *) mkdir -p "$BACKUP_DIR/$(dirname "$rel")"; mv "$target" "$BACKUP_DIR/$rel"; warn "moved foreign symlink $target ($dest) to backup" ;;
      esac
    elif [[ -e "$target" ]]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      mv "$target" "$BACKUP_DIR/$rel"
      warn "backed up $target -> $BACKUP_DIR/$rel"
    fi
  done
}

link_packages() {
  have stow || die "GNU stow is not installed"
  for pkg in "$@"; do
    [[ -d "$DOTFILES/$pkg" ]] || { warn "no such package: $pkg"; continue; }
    backup_conflicts "$pkg"
    log "stow $pkg"
    stow -d "$DOTFILES" -t "$HOME" -R "$pkg"
  done
}

write_local_templates() {
  if [[ ! -f "$HOME/.secrets" ]]; then
    cat > "$HOME/.secrets" <<'EOF'
# API keys and tokens. Sourced by ~/.zshrc. NEVER commit this file.
# export ANTHROPIC_API_KEY=...
# export GEMINI_API_KEY=...
EOF
    chmod 600 "$HOME/.secrets"
    log "created ~/.secrets (add your API keys there)"
  fi
  if [[ ! -f "$HOME/.zshrc.local" ]]; then
    cat > "$HOME/.zshrc.local" <<'EOF'
# Machine-specific zsh config, sourced at the end of ~/.zshrc. Not in git.
# Put installer-appended PATH lines, host-only aliases etc. here.
EOF
    log "created ~/.zshrc.local"
  fi
  if [[ ! -f "$HOME/.gitconfig.local" ]]; then
    cat > "$HOME/.gitconfig.local" <<'EOF'
# Machine-specific git config, included from ~/.gitconfig. Not in git.
# [maintenance]
#	repo = /path/to/big/repo
EOF
    log "created ~/.gitconfig.local"
  fi
}

# ---------------------------------------------------------------------------
# Neovim
# ---------------------------------------------------------------------------
bootstrap_nvim() {
  have nvim || { warn "nvim not installed; skipping plugin bootstrap"; return; }
  # node must be on PATH for mason (ts_ls, prettierd, eslint_d)
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  # shellcheck disable=SC1091
  [[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh" >/dev/null 2>&1 || true
  # A lazy.nvim checkout that was interrupted mid-clone makes init.lua skip the
  # clone forever (it only checks that the directory exists) — remove it.
  local lazydir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
  if [[ -d "$lazydir" && ! -f "$lazydir/lua/lazy/init.lua" ]]; then
    warn "removing broken lazy.nvim checkout at $lazydir"
    rm -rf "$lazydir"
  fi
  log "nvim: installing plugins (lazy.nvim sync)"
  nvim --headless "+Lazy! sync" +qa 2>&1 | tail -n 5 || warn "lazy sync reported errors"
  log "nvim: treesitter parsers"
  nvim --headless "+TSUpdateSync" +qa >/dev/null 2>&1 || warn "TSUpdateSync reported errors"
  log "nvim: mason tools (lsp servers / formatters)"
  nvim --headless "+MasonToolsInstallSync" +qa >/dev/null 2>&1 || warn "MasonToolsInstallSync reported errors"
}

# ---------------------------------------------------------------------------
# Doctor
# ---------------------------------------------------------------------------
doctor() {
  if [[ -x "$DOTFILES/bin/.local/bin/dotfiles-doctor" ]]; then
    "$DOTFILES/bin/.local/bin/dotfiles-doctor"
  fi
}
