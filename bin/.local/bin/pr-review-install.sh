#!/usr/bin/env bash
#
# PR Review Automation - Installation Script
# Sets up the PR review automation tool with launchd scheduling
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${SCRIPT_DIR%/bin/.local/bin}"

echo -e "${BLUE}PR Review Automation - Installation${NC}"
echo "======================================"
echo ""

# Check for required dependencies
check_dependencies() {
    echo -e "${BLUE}Checking dependencies...${NC}"
    local missing=()

    for cmd in gh tmux terminal-notifier git stow; do
        if command -v "$cmd" &> /dev/null; then
            echo -e "  ${GREEN}✓${NC} $cmd"
        else
            echo -e "  ${RED}✗${NC} $cmd (missing)"
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        echo -e "${YELLOW}Install missing dependencies with:${NC}"
        echo "  brew install ${missing[*]}"
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    # Check gh auth
    echo ""
    echo -e "${BLUE}Checking GitHub CLI authentication...${NC}"
    if gh auth status &> /dev/null; then
        echo -e "  ${GREEN}✓${NC} GitHub CLI authenticated"
    else
        echo -e "  ${RED}✗${NC} GitHub CLI not authenticated"
        echo ""
        echo "  Run: gh auth login"
        exit 1
    fi
}

# Create directory structure
setup_directories() {
    echo ""
    echo -e "${BLUE}Setting up directories...${NC}"

    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/state/pr-review"
    mkdir -p "$HOME/.config/pr-review/project-scripts"
    mkdir -p "$HOME/Library/LaunchAgents"

    echo -e "  ${GREEN}✓${NC} Created ~/.local/bin"
    echo -e "  ${GREEN}✓${NC} Created ~/.local/state/pr-review"
    echo -e "  ${GREEN}✓${NC} Created ~/.config/pr-review"
}

# Use stow to symlink files
setup_stow() {
    echo ""
    echo -e "${BLUE}Symlinking files with stow...${NC}"

    cd "$DOTFILES_DIR"

    # Stow bin (contains the main script)
    stow -D bin 2>/dev/null || true
    stow bin
    echo -e "  ${GREEN}✓${NC} Stowed bin/"

    # Stow config (contains pr-review config)
    stow -D config 2>/dev/null || true
    stow config
    echo -e "  ${GREEN}✓${NC} Stowed config/"
}

# Install launchd plist
install_launchd() {
    echo ""
    echo -e "${BLUE}Installing launchd service...${NC}"

    local plist_src="${DOTFILES_DIR}/launchd/com.user.pr-review.plist"
    local plist_dst="$HOME/Library/LaunchAgents/com.user.pr-review.plist"

    # Unload existing service if present
    if launchctl list | grep -q "com.user.pr-review"; then
        echo "  Unloading existing service..."
        launchctl unload "$plist_dst" 2>/dev/null || true
    fi

    # Copy and substitute placeholders
    sed -e "s|__HOME__|$HOME|g" \
        -e "s|__USER__|$USER|g" \
        "$plist_src" > "$plist_dst"

    echo -e "  ${GREEN}✓${NC} Installed plist to ~/Library/LaunchAgents/"

    # Load the service
    launchctl load "$plist_dst"
    echo -e "  ${GREEN}✓${NC} Loaded launchd service"
}

# Create work directory if needed
setup_work_dir() {
    echo ""
    echo -e "${BLUE}Checking work directory...${NC}"

    if [[ -d "$HOME/work" ]]; then
        echo -e "  ${GREEN}✓${NC} ~/work exists"
    else
        echo -e "  ${YELLOW}!${NC} ~/work does not exist"
        read -p "  Create ~/work directory? (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            mkdir -p "$HOME/work"
            echo -e "  ${GREEN}✓${NC} Created ~/work"
        fi
    fi
}

# Print summary
print_summary() {
    echo ""
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Files installed:"
    echo "  - ~/.local/bin/pr-review-automation.sh"
    echo "  - ~/.config/pr-review/config.sh"
    echo "  - ~/.config/pr-review/project-scripts/example.sh"
    echo "  - ~/Library/LaunchAgents/com.user.pr-review.plist"
    echo ""
    echo "Usage:"
    echo "  pr-review-automation.sh             # Run manually"
    echo "  pr-review-automation.sh --dry-run   # Preview without changes"
    echo "  pr-review-automation.sh status      # Show active sessions"
    echo "  pr-review-automation.sh cleanup     # Remove old sessions"
    echo ""
    echo "The service will automatically check for PRs every 30 minutes."
    echo ""
    echo "To configure project-specific scripts:"
    echo "  cp ~/.config/pr-review/project-scripts/example.sh \\"
    echo "     ~/.config/pr-review/project-scripts/owner-repo.sh"
    echo ""
    echo "Logs:"
    echo "  /tmp/pr-review.log"
    echo "  /tmp/pr-review-error.log"
    echo "  ~/.local/state/pr-review/pr-review.log"
}

# Uninstall function
uninstall() {
    echo -e "${BLUE}Uninstalling PR Review Automation...${NC}"

    # Unload launchd service
    local plist="$HOME/Library/LaunchAgents/com.user.pr-review.plist"
    if [[ -f "$plist" ]]; then
        launchctl unload "$plist" 2>/dev/null || true
        rm "$plist"
        echo -e "  ${GREEN}✓${NC} Removed launchd service"
    fi

    # Kill any active review sessions
    for session in $(tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -E "pr-[0-9]+"); do
        tmux kill-session -t "$session" 2>/dev/null || true
    done
    echo -e "  ${GREEN}✓${NC} Killed active review sessions"

    echo ""
    echo "Note: The following were NOT removed (use stow -D to remove):"
    echo "  - ~/.local/bin/pr-review-automation.sh"
    echo "  - ~/.config/pr-review/"
    echo ""
    echo "Uninstall complete."
}

# Main
main() {
    case "${1:-}" in
        --uninstall)
            uninstall
            exit 0
            ;;
        --help|-h)
            echo "Usage: pr-review-install.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --uninstall   Remove launchd service and cleanup"
            echo "  --help        Show this help message"
            exit 0
            ;;
    esac

    check_dependencies
    setup_directories
    setup_stow
    install_launchd
    setup_work_dir
    print_summary
}

main "$@"
