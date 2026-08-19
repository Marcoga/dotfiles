#!/usr/bin/env bash
# Debian/Ubuntu package installation. Sourced by install.sh.
# apt for the basics; neovim / lazygit / gitmux come from GitHub releases
# because distro packages are too old for this config (blink.cmp needs nvim >= 0.10).

NVIM_MIN="0.11"

arch_tag() {
  case "$(uname -m)" in
    x86_64|amd64) echo x86_64 ;;
    aarch64|arm64) echo arm64 ;;
    *) die "unsupported architecture $(uname -m)" ;;
  esac
}

# Download the asset of a GitHub release whose name matches a pattern.
# gh_release_asset <owner/repo> <grep-pattern> <dest-file>
gh_release_asset() {
  local repo="$1" pattern="$2" dest="$3" url
  url="$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -o '"browser_download_url": *"[^"]*"' | cut -d'"' -f4 | grep -iE "$pattern" | head -1)"
  [[ -n "$url" ]] || die "no release asset for $repo matching $pattern"
  log "downloading $url"
  curl -fsSL -o "$dest" "$url"
}

version_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -1)" == "$2" ]]; }

install_apt_packages() {
  log "apt packages"
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    zsh git git-lfs stow tmux fzf ripgrep fd-find jq curl wget unzip tar \
    build-essential fontconfig xclip ca-certificates gh htop \
    >/dev/null
  # Debian names fd "fdfind"
  if ! have fd && have fdfind; then ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
}

install_neovim_linux() {
  local cur=""
  if have nvim; then cur="$(nvim --version | head -1 | sed 's/^NVIM v//')"; fi
  if [[ -n "$cur" ]] && version_ge "$cur" "$NVIM_MIN"; then
    log "neovim $cur already installed"; return
  fi
  local arch; arch="$(arch_tag)"
  local tmp; tmp="$(mktemp -d)"
  gh_release_asset neovim/neovim "nvim-linux-${arch}\.tar\.gz$" "$tmp/nvim.tar.gz"
  rm -rf "$HOME/.local/nvim"
  mkdir -p "$HOME/.local/nvim"
  tar -xzf "$tmp/nvim.tar.gz" -C "$HOME/.local/nvim" --strip-components=1
  ln -sf "$HOME/.local/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  rm -rf "$tmp"
  log "neovim installed: $("$HOME/.local/bin/nvim" --version | head -1)"
}

install_lazygit_linux() {
  have lazygit && { log "lazygit already installed"; return; }
  local arch; arch="$(arch_tag)"
  local tmp; tmp="$(mktemp -d)"
  gh_release_asset jesseduffield/lazygit "lazygit_.*_Linux_${arch}\.tar\.gz$" "$tmp/lazygit.tar.gz"
  tar -xzf "$tmp/lazygit.tar.gz" -C "$tmp" lazygit
  install -m 755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$tmp"
}

install_gitmux_linux() {
  have gitmux && { log "gitmux already installed"; return; }
  local arch; arch="$(arch_tag)"
  [[ "$arch" == x86_64 ]] && arch=amd64
  local tmp; tmp="$(mktemp -d)"
  gh_release_asset arl/gitmux "gitmux_.*_linux_${arch}\.tar\.gz$" "$tmp/gitmux.tar.gz"
  tar -xzf "$tmp/gitmux.tar.gz" -C "$tmp" gitmux
  install -m 755 "$tmp/gitmux" "$HOME/.local/bin/gitmux"
  rm -rf "$tmp"
}

install_deno_linux() {
  have deno || [[ -x "$HOME/.deno/bin/deno" ]] && { log "deno already installed"; return; }
  log "installing deno (peek.nvim markdown preview)"
  curl -fsSL https://deno.land/install.sh | DENO_INSTALL="$HOME/.deno" sh -s -- -y >/dev/null 2>&1 \
    || warn "deno install failed (only peek.nvim needs it)"
}

install_nerd_font_linux() {
  local fontdir="$HOME/.local/share/fonts"
  if ls "$fontdir"/FiraCodeNerdFont* >/dev/null 2>&1; then log "nerd font already installed"; return; fi
  log "installing FiraCode Nerd Font -> $fontdir"
  mkdir -p "$fontdir"
  local tmp; tmp="$(mktemp -d)"
  gh_release_asset ryanoasis/nerd-fonts "FiraCode\.zip$" "$tmp/FiraCode.zip"
  unzip -q -o "$tmp/FiraCode.zip" -d "$fontdir" '*.ttf' || true
  fc-cache -f >/dev/null 2>&1 || true
  rm -rf "$tmp"
}

install_packages_linux() {
  mkdir -p "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
  install_apt_packages
  install_neovim_linux
  install_lazygit_linux
  install_gitmux_linux
  install_deno_linux
  install_nerd_font_linux
}
