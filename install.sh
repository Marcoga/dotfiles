#!/usr/bin/env bash
#
# install.sh — one command to set up this machine from ~/dotfiles.
#
#   git clone https://github.com/Marcoga/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh
#
# Detects macOS / Debian-Ubuntu, installs the tools (Homebrew Brewfile or apt +
# GitHub releases), oh-my-zsh + plugins, nvm, stows the config packages,
# bootstraps neovim plugins and prints a doctor summary. Idempotent: re-run it
# after `git pull` to pick up changes.
#
# Flags:
#   --no-packages   skip brew/apt tool installation (just link + shell + nvim)
#   --no-nvim       skip the headless neovim plugin/LSP bootstrap
#   --with launchd  also stow the launchd package (macOS pr-review agent)
#   --only-link     only (re)stow the packages — nothing else
#   --packages "a b"  override the stow package list
#   -h, --help
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES

# shellcheck source=bootstrap/common.sh
source "$DOTFILES/bootstrap/common.sh"

DO_PACKAGES=1
DO_NVIM=1
ONLY_LINK=0
EXTRA_PACKAGES=()
PACKAGES_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-packages) DO_PACKAGES=0 ;;
    --no-nvim) DO_NVIM=0 ;;
    --only-link) ONLY_LINK=1 ;;
    --with) shift; EXTRA_PACKAGES+=("$1") ;;
    --packages) shift; PACKAGES_OVERRIDE="$1" ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) die "unknown flag: $1 (see --help)" ;;
  esac
  shift
done

STOW_PACKAGES=(zsh tmux nvim git bin config)
if [[ -n "$PACKAGES_OVERRIDE" ]]; then
  # shellcheck disable=SC2206
  STOW_PACKAGES=($PACKAGES_OVERRIDE)
fi
STOW_PACKAGES+=("${EXTRA_PACKAGES[@]+"${EXTRA_PACKAGES[@]}"}")

OS="$(detect_os)"
log "dotfiles: $DOTFILES  os: $OS  user: $USER  home: $HOME"

preflight_checks
ensure_skeleton_dirs

if [[ $ONLY_LINK -eq 1 ]]; then
  link_packages "${STOW_PACKAGES[@]}"
  doctor
  exit 0
fi

if [[ $DO_PACKAGES -eq 1 ]]; then
  case "$OS" in
    macos) source "$DOTFILES/bootstrap/macos.sh"; install_packages_macos ;;
    linux) source "$DOTFILES/bootstrap/linux.sh"; install_packages_linux ;;
    *) die "unsupported OS: $OS" ;;
  esac
fi

install_oh_my_zsh
install_zsh_plugins
install_nvm
link_packages "${STOW_PACKAGES[@]}"
write_local_templates
ensure_default_shell_zsh

if [[ $DO_NVIM -eq 1 ]]; then
  bootstrap_nvim
fi

doctor
log "done. Open a new terminal (or: exec zsh)."
