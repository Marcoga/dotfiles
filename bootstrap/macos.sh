#!/usr/bin/env bash
# macOS package installation. Sourced by install.sh.

install_packages_macos() {
  if ! xcode-select -p >/dev/null 2>&1; then
    log "installing Xcode command line tools (a dialog will open; re-run install.sh when it finishes)"
    xcode-select --install || true
    die "Xcode CLT install started — re-run ./install.sh once it completes"
  fi

  if ! have brew; then
    log "installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  log "brew bundle (bootstrap/Brewfile)"
  brew bundle --file "$DOTFILES/bootstrap/Brewfile" --no-upgrade || warn "brew bundle reported failures (see above)"
}
