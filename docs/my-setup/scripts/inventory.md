# Scripts Inventory

Location: `~/scripts/`

## Task Management

| Script | Purpose |
|--------|---------|
| `task-add.sh` | CLI task creation with smart defaults |
| `task-add-obsidian.sh` | Obsidian Shell Commands integration |
| `task-add-dialog.sh` | AppleScript dialog for task entry |
| `task-toggle-done.sh` | Toggle task completion in frontmatter |

## PR Management

| Script | Purpose |
|--------|---------|
| `pr-dashboard.sh` | Terminal fzf dashboard for PRs |
| `sync-prs-to-obsidian.sh` | Sync GitHub PRs to Obsidian vault |
| `review-pr-with-tmux.sh` | Create worktree + tmux session for PR |
| `review-pr-with-claude.sh` | Review PR, append to note |
| `run-claude-review.sh` | Run Claude review, output to file |

## Claude Code Usage

| Script | Purpose |
|--------|---------|
| `claude-usage.sh` | Main terminal dashboard |
| `claude-usage-obsidian.sh` | Generate Obsidian markdown report |
| `claude-usage-chart.sh` | SVG burn chart generator |
| `claude-usage-limits-chart.sh` | SVG rate limit visualization |
| `claude-usage-weekly-chart.sh` | SVG weekly breakdown |
| `claude-usage-alert.sh` | Cron-based usage alerts |

## Planning

| Script | Purpose |
|--------|---------|
| `plan-create.sh` | Create new plan file with template |
| `plan-focus.sh` | Create plan if missing, open in Obsidian |

## Integration

| Script | Purpose |
|--------|---------|
| `claude-with-prompt.sh` | Launch Claude with prompt file |
| `attach-tmux-session.sh` | Switch tmux session, open iTerm if needed |

## Scripts in dotfiles

Already in `~/dotfiles/bin/.local/bin/`:

| Script | Purpose |
|--------|---------|
| `pr-review-automation.sh` | Main PR automation orchestrator |
| `pr-review-install.sh` | Installation script |
| `tmux-sessionizer` | Fuzzy project finder |
| `tmux-session-picker` | Existing session switcher |
| `tmux-window-opener` | Window/pane picker |

## Migration Candidates

Scripts to move to `~/dotfiles/bin/.local/bin/`:

### High Priority (core workflow)
- `pr-dashboard.sh`
- `sync-prs-to-obsidian.sh`
- `review-pr-with-tmux.sh`
- `attach-tmux-session.sh`

### Medium Priority (utilities)
- `task-add.sh`
- `task-add-obsidian.sh`
- `task-toggle-done.sh`
- `claude-usage.sh`
- `claude-usage-obsidian.sh`

### Lower Priority (specialized)
- `claude-usage-chart.sh`
- `claude-usage-limits-chart.sh`
- `claude-usage-weekly-chart.sh`
- `claude-usage-alert.sh`
- `plan-create.sh`
- `plan-focus.sh`

### Keep Separate
- `task-add-dialog.sh` (AppleScript, machine-specific)
- `review-pr-with-claude.sh` (may merge with automation)
- `run-claude-review.sh` (may merge with automation)
