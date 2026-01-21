# PR Review Automation Tool

Automatically detect GitHub PRs requiring your review, create isolated worktrees, launch Claude Code review sessions, and receive macOS notifications.

## Features

- Scans all repos in `~/work/` for PRs assigned to you for review
- Creates git worktrees for each PR (isolated from your main branch)
- Launches tmux sessions with Claude Code for each review
- Sends macOS notifications with "Open" button to jump to the session
- Runs project-specific scripts (linting, type checking) before review
- Runs automatically on a schedule via launchd

## Prerequisites

Install required dependencies:

```bash
brew install gh tmux terminal-notifier stow
```

Authenticate with GitHub CLI:

```bash
gh auth login
```

## Installation

From your dotfiles directory:

```bash
./bin/.local/bin/pr-review-install.sh
```

This will:
1. Check for required dependencies
2. Symlink scripts and config files using stow
3. Install and load the launchd service
4. Create necessary directories

## Configuration

### Main Config (`~/.config/pr-review/config.sh`)

```bash
# Work directory containing git repos
WORK_DIR="$HOME/work"

# Claude Code review prompt
CLAUDE_REVIEW_PROMPT="Review this PR for code quality, potential bugs, security issues, and suggest improvements"

# Terminal application ("Terminal" or "iTerm")
TERMINAL_APP="Terminal"
```

### Project-Specific Scripts

Create scripts for specific projects to run commands before Claude Code starts:

```bash
# Copy the example
cp ~/.config/pr-review/project-scripts/example.sh \
   ~/.config/pr-review/project-scripts/owner-repo.sh
```

For a repo at `https://github.com/mycompany/myproject`, name the file `mycompany-myproject.sh`.

Example project script:

```bash
#!/usr/bin/env bash

run_tsc() {
    if [[ -f "tsconfig.json" ]]; then
        echo "Running TypeScript compiler..."
        npx tsc --noEmit 2>&1 || true
    fi
}

run_lint() {
    if [[ -f "package.json" ]] && grep -q '"lint"' package.json; then
        echo "Running linter..."
        npm run lint 2>&1 || true
    fi
}

PROJECT_COMMANDS=(
    "run_tsc"
    "run_lint"
)
```

### Skip Specific Repos

Create a `.pr-review-ignore` file in any repo you want to skip:

```bash
touch ~/work/some-repo/.pr-review-ignore
```

## Usage

### Manual Execution

```bash
# Run the automation
pr-review-automation.sh

# Preview what would happen (no changes)
pr-review-automation.sh --dry-run

# Verbose output
pr-review-automation.sh --verbose
```

### Managing Sessions

```bash
# List active review sessions
pr-review-automation.sh status

# Attach to a session manually
tmux attach -t owner-repo-pr-123

# List all tmux sessions
tmux list-sessions
```

### Cleanup

```bash
# Remove all PR review sessions and worktrees
pr-review-automation.sh cleanup
```

### Managing the Service

```bash
# Check if service is running
launchctl list | grep pr-review

# Manually trigger the service
launchctl start com.user.pr-review

# Stop the service
launchctl unload ~/Library/LaunchAgents/com.user.pr-review.plist

# Start the service
launchctl load ~/Library/LaunchAgents/com.user.pr-review.plist
```

## How It Works

1. **Repo Discovery**: Scans `~/work/` for directories containing git repos with GitHub remotes
2. **PR Detection**: Uses `gh pr list --search "review-requested:@me"` to find PRs
3. **Worktree Creation**: Creates a git worktree at `{repo}-pr-{number}` for each PR
4. **Session Setup**: Creates a tmux session named `{owner-repo}-pr-{number}`
5. **Project Scripts**: Runs any configured project-specific commands
6. **Claude Code**: Launches Claude with the `/review-pr` command
7. **Notification**: Sends a macOS notification for new sessions only

### Worktree Structure

For a PR #42 in `~/work/myproject`:
- Worktree: `~/work/myproject-pr-42`
- Tmux session: `owner-myproject-pr-42`

## Logs

- Service output: `/tmp/pr-review.log`
- Service errors: `/tmp/pr-review-error.log`
- Script log: `~/.local/state/pr-review/pr-review.log`

View logs:

```bash
tail -f /tmp/pr-review.log
tail -f ~/.local/state/pr-review/pr-review.log
```

## Uninstall

```bash
./bin/.local/bin/pr-review-install.sh --uninstall
```

To fully remove:

```bash
cd ~/dotfiles
stow -D bin
stow -D config
rm -rf ~/.local/state/pr-review
```

## Troubleshooting

### Notifications not appearing

1. Check System Preferences > Notifications > terminal-notifier
2. Ensure terminal-notifier is allowed

### Service not running

```bash
# Check status
launchctl list | grep pr-review

# Check for errors
cat /tmp/pr-review-error.log

# Reload service
launchctl unload ~/Library/LaunchAgents/com.user.pr-review.plist
launchctl load ~/Library/LaunchAgents/com.user.pr-review.plist
```

### GitHub CLI errors

```bash
# Re-authenticate
gh auth login

# Check auth status
gh auth status
```

### Worktree conflicts

If a worktree creation fails:

```bash
# List worktrees for a repo
cd ~/work/myproject
git worktree list

# Remove a broken worktree
git worktree remove ~/work/myproject-pr-42 --force
```

## File Locations

```
~/.local/bin/
├── pr-review-automation.sh    # Main script
└── pr-review-install.sh       # Installation script

~/.config/pr-review/
├── config.sh                  # Configuration
└── project-scripts/           # Per-project scripts
    └── example.sh

~/.local/state/pr-review/
├── pr-review.log              # Script logs
└── open-*.sh                  # Notification click handlers

~/Library/LaunchAgents/
└── com.user.pr-review.plist   # launchd service
```
