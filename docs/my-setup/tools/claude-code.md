# Claude Code Integration

Claude Code (CC) is integrated throughout the workflow via tmux sessions, Obsidian shell commands, and automation scripts.

## Key Integration Points

### 1. CLAUDE_CONTEXT.md

Master reference file at `~/obsidian-vault/CLAUDE_CONTEXT.md` (270 lines).

Contains:
- Directory structure explanation
- Script descriptions
- Frontmatter schemas
- Naming conventions
- Shell command mappings
- Common operations
- Debugging tips

CC reads this when working in the vault to understand the setup.

### 2. PR Review Automation

`pr-review-automation.sh` launches CC sessions for PR reviews:

```bash
# Automated flow
1. Scans ~/work/ for repos with assigned PRs
2. Creates git worktree: {repo}/pr-{number}
3. Creates tmux session: {owner-repo}-pr-{number}
4. Launches Claude Code with /review-pr
```

### 3. Obsidian Shell Commands

CC can be launched from Obsidian with context:

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+O` | Open CC in ~/work/i360/main |
| `Cmd+Shift+R` | Review current PR note |
| `Cmd+Shift+T` | Review in worktree + tmux |

### 4. Prompt Files

Located in `~/obsidian-vault/PRs/prompts/`:

| File | Purpose |
|------|---------|
| `work-on-next-items.md` | Context for dashboard tasks |
| `work-on-plan.md` | Context for plan execution |

Used by `claude-with-prompt.sh` to pass context.

### 5. Token Usage Monitoring

Scripts in `~/scripts/`:

| Script | Purpose |
|--------|---------|
| `claude-usage.sh` | Terminal dashboard (main) |
| `claude-usage-obsidian.sh` | Generate Obsidian report |
| `claude-usage-chart.sh` | SVG burn chart |
| `claude-usage-limits-chart.sh` | Rate limit visualization |
| `claude-usage-weekly-chart.sh` | Weekly breakdown |
| `claude-usage-alert.sh` | Cron-based alerts |

Aliases:
- `ccusage` - Terminal dashboard
- `ccusage-update` - Update Obsidian report

### 6. Session Data

CC stores data in `~/.claude/`:

```
~/.claude/
├── stats-cache.json              # Aggregated stats
├── projects/{hash}/
│   ├── sessions-index.json       # Session index
│   └── {session-id}.jsonl        # Session transcripts
```

## Configuration

### Global CLAUDE.md

`~/.claude/CLAUDE.md` contains:
- Preference to open .md files with MacDown
- Dashboard/task system instructions
- References to obsidian vault paths

### Project CLAUDE.md

`~/dotfiles/CLAUDE.md` contains repo-specific instructions for CC when working in dotfiles.

## Workflows

### Working on Dashboard Tasks

1. CC reads `CLAUDE_CONTEXT.md` for context
2. Opens `Dashboard.md` to find "Next Steps"
3. Works through unchecked items
4. Marks completed

Triggered by: "next steps", "dashboard tasks", "work on the list"

### PR Review Session

1. `Cmd+Shift+T` from Obsidian PR note
2. Creates/switches to worktree
3. Creates tmux session
4. Runs Claude with `/review-pr`
5. Updates `claude_last_review` timestamp

### Token Budget Monitoring

```bash
ccusage           # View current usage
ccusage --weekly  # Weekly breakdown
ccusage --chart   # SVG burn chart
```

## Smart Review Tracking

PR notes track `claude_last_review` in frontmatter:

```yaml
claude_last_review: 2026-01-23T14:30:00
```

Automation skips re-review if no new commits since last review.

## Tips

- CC sessions persist in tmux - use `prefix+k` to switch between them
- `pr-dashboard.sh` (`prefix+g`) shows all active PR sessions
- Use `--resume` flag to continue previous session
- Check `/tmp/pr-review.log` for automation issues
