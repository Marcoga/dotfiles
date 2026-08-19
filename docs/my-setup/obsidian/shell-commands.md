# Obsidian Shell Commands

The Shell Commands plugin maps keyboard shortcuts to scripts, enabling deep integration between Obsidian and the terminal workflow.

## Command Reference

| ID | Shortcut | Command | Description |
|----|----------|---------|-------------|
| cmd-1 | `Cmd+Shift+S` | `~/scripts/sync-prs-to-obsidian.sh` | Sync PRs from GitHub |
| cmd-2 | `Cmd+Shift+O` | Opens iTerm with Claude | Open Claude Code in i360/main |
| cmd-3 | `Cmd+Shift+B` | `git checkout {{clipboard}}` | Checkout branch from clipboard |
| cmd-4 | `Cmd+Shift+C` | Claude with note context | AI analysis of current note |
| cmd-5 | `Cmd+Shift+G` | `open {{frontmatter:url}}` | Open PR in GitHub |
| cmd-6 | `Cmd+Shift+R` | `~/scripts/review-pr-with-claude.sh` | Claude review current PR |
| cmd-7 | `Cmd+Shift+T` | `~/scripts/review-pr-with-tmux.sh` | Review in worktree + tmux |
| cmd-9 | (custom) | `~/scripts/attach-tmux-session.sh` | Switch to tmux session |
| cmd-10 | `Cmd+Shift+A` | `~/scripts/task-add-obsidian.sh` | Add task to inbox |
| cmd-11 | (dashboard) | Claude with next items prompt | Work on dashboard tasks |
| cmd-12 | (dashboard) | `~/scripts/task-toggle-done.sh` | Toggle task completion |

## Variable Syntax

Shell Commands plugin supports variables:

| Variable | Description |
|----------|-------------|
| `{{clipboard}}` | System clipboard content |
| `{{frontmatter:key}}` | Value from note frontmatter |
| `{{file_path}}` | Current file path |
| `{{folder_path}}` | Current folder path |
| `{{title}}` | Note title |

## Command Details

### cmd-1: Sync PRs

```bash
~/scripts/sync-prs-to-obsidian.sh
```

- Queries GitHub CLI for PRs
- Creates/updates notes in `PRs/authored/` and `PRs/reviews/`
- Updates `sync-status.md` timestamp

### cmd-2: Open Claude Code

Opens iTerm and runs:
```bash
cd ~/work/i360/main && claude --resume
```

### cmd-5: Open PR in GitHub

Uses frontmatter variable:
```bash
open {{frontmatter:url}}
```

Reads `url` from current note's YAML frontmatter.

### cmd-7: Review in Worktree + Tmux

```bash
~/scripts/review-pr-with-tmux.sh "{{frontmatter:pr_number}}" "{{frontmatter:repo}}"
```

1. Creates git worktree if needed
2. Creates/attaches tmux session
3. Launches Claude Code with `/review-pr`

### cmd-10: Add Task

```bash
~/scripts/task-add-obsidian.sh
```

- Analyzes last 5 tasks for smart defaults
- Creates note in `Inbox/`
- Opens new note in Obsidian

### cmd-12: Toggle Done

```bash
~/scripts/task-toggle-done.sh "{{file_path}}"
```

Toggles `done: true/false` in frontmatter.

## Configuration Location

Plugin settings stored in:
```
~/obsidian-vault/.obsidian/plugins/obsidian-shellcommands/data.json
```

## Setting Up New Commands

1. Open Settings → Shell Commands
2. Click "New command"
3. Enter shell command with variables
4. Set alias (display name)
5. Assign hotkey in Settings → Hotkeys

## Troubleshooting

### Command not running

Check:
- Script has execute permission (`chmod +x`)
- Script path is absolute
- Shell environment has required tools in PATH

### Variable not expanding

Ensure:
- Variable name matches exactly (case-sensitive)
- Frontmatter key exists in current note
- Note is saved (frontmatter read from disk)

### Output not visible

Shell Commands can show output in:
- Notification
- Modal
- Console (View → Toggle Developer Tools)

Configure in command settings.

## Integration with Claude Code

Commands that launch Claude:
- `cmd-2`: Opens Claude in main project
- `cmd-4`: Passes note content to Claude
- `cmd-6`: Claude review of PR
- `cmd-7`: Claude review in isolated worktree
- `cmd-11`: Claude works on dashboard tasks

Context is passed via:
- File content (first N lines)
- Frontmatter variables
- Prompt files in `PRs/prompts/`
