# PR Review Workflow

End-to-end automation for reviewing GitHub PRs with isolated environments and Claude Code assistance.

## Overview

```
GitHub PR assigned → Automation detects → Worktree created → Tmux session → Claude review → Obsidian note updated
```

## Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `pr-review-automation.sh` | `~/.local/bin/` | Main orchestrator |
| `sync-prs-to-obsidian.sh` | `~/scripts/` | GitHub → Obsidian sync |
| `review-pr-with-tmux.sh` | `~/scripts/` | Manual trigger from Obsidian |
| `pr-dashboard.sh` | `~/scripts/` | Terminal fzf browser |
| LaunchD service | `~/dotfiles/launchd/` | Scheduled execution (30 min) |

## Automated Flow

### 1. Discovery

`pr-review-automation.sh` runs every 30 minutes (LaunchD):

```bash
# Scans ~/work/ for repos with GitHub remotes
# Queries: gh pr list --search "review-requested:@me"
```

### 2. Worktree Creation

For each PR:

```bash
# Fetch PR branch
git fetch origin pull/{number}/head:pr-{number}

# Create worktree
git worktree add ../pr-{number} pr-{number}
```

Result: `~/work/i360/pr-5156/`

### 3. Tmux Session

```bash
# Session naming: {owner-repo}-pr-{number}
tmux new-session -d -s "dcodeit-i360-pr-5156" -c ~/work/i360/pr-5156
```

### 4. Project Setup

Runs project-specific scripts from `~/.config/pr-review/project-scripts/`:

```bash
# Example: dcodeit-i360.sh
pnpm install
pnpm type-check
pnpm lint
```

### 5. Claude Review

```bash
# Launches Claude Code with review command
claude /review-pr
```

### 6. Notification

macOS notification with "Open" button to jump to tmux session.

## Manual Triggers

### From Obsidian

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+T` | Review PR in worktree + tmux |
| `Cmd+Shift+R` | Claude review only |

### From Terminal

```bash
# Full automation
pr-review-automation.sh

# Dry run (preview)
pr-review-automation.sh --dry-run

# Status check
pr-review-automation.sh status

# Cleanup old worktrees
pr-review-automation.sh cleanup
```

### From tmux

`prefix + g` opens `pr-dashboard.sh`:

- Browse all PRs with fzf
- Filter: authored, reviews, closed, all
- Actions: open Obsidian, GitHub, tmux, run Claude

## Obsidian Integration

### PR Notes

Location: `~/obsidian-vault/PRs/authored/` and `~/obsidian-vault/PRs/reviews/`

Frontmatter schema:

```yaml
pr_number: 5156
title: "feat: add feature"
repo: i360
url: https://github.com/dcodeit/i360/pull/5156
status: open
type: authored|review
branch: feature-name
created: 2026-01-22
updated: 2026-01-22
claude_last_review: 2026-01-23T14:30:00
labels: [feature]
reviewers: []
my_review_status: pending
```

### Dashboard

`~/obsidian-vault/PRs/Dashboard.md` shows:

- My Open PRs (with quick-action buttons)
- PRs Needing Review
- Recently Closed

### Sync

`Cmd+Shift+S` runs `sync-prs-to-obsidian.sh`:
- Creates/updates PR notes
- Tracks sync status in `sync-status.md`

## Smart Review Tracking

`claude_last_review` timestamp prevents redundant reviews:

1. Automation checks last commit date
2. Compares to `claude_last_review`
3. Skips if no new commits

## Configuration

### Main Config

`~/.config/pr-review/config.sh`:

```bash
WORK_DIR=~/work
CLAUDE_REVIEW_PROMPT="Review this PR..."
TERMINAL_APP=iTerm
```

### Project Scripts

`~/.config/pr-review/project-scripts/{owner-repo}.sh`:

```bash
#!/bin/bash
# Setup for dcodeit/i360
pnpm install
pnpm type-check
```

### Skip Repos

Create `.pr-review-ignore` in repo root to exclude from automation.

## Logs

| Log | Location |
|-----|----------|
| Service output | `/tmp/pr-review.log` |
| Service errors | `/tmp/pr-review-error.log` |
| Script logs | `~/.local/state/pr-review/pr-review.log` |

## Cleanup

```bash
# Remove old worktrees and sessions
pr-review-automation.sh cleanup

# Manual removal
git worktree remove ~/work/i360/pr-5156
git branch -D pr-5156
tmux kill-session -t dcodeit-i360-pr-5156
```
