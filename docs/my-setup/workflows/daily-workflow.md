# Daily Workflow

How all the tools connect in practice.

## Morning Startup

### 1. Open Terminal

iTerm opens with zsh + oh-my-zsh.

### 2. Quick Project Access

```bash
# Ctrl+F to launch tmux-sessionizer
# Fuzzy-find project in ~/work or ~/personal
# Creates/attaches tmux session
```

### 3. Check PRs

```bash
# In tmux, prefix+g for PR dashboard
# Or open Obsidian Dashboard
```

## Development Session

### Tmux Layout

```
┌─────────────────────────────────────────┐
│ Session: i360_main                      │
├─────────────────────────────────────────┤
│ Window 1: nvim                          │
│ ┌───────────────┬───────────────────────┤
│ │ Code          │ Terminal              │
│ │ (nvim)        │ (shell)               │
│ │               │                       │
│ └───────────────┴───────────────────────┤
│ Window 2: servers                       │
│ Window 3: logs                          │
└─────────────────────────────────────────┘
```

### Navigation

| Action | Command |
|--------|---------|
| Switch panes | `Alt+Arrow` |
| Switch windows | `prefix+number` |
| Switch sessions | `prefix+k` (session picker) |
| New window | `prefix+c` |
| Split horizontal | `prefix+\` |
| Split vertical | `prefix+-` |

### In Neovim

| Action | Command |
|--------|---------|
| Find files | `<leader>e` (telescope) |
| File browser | `<leader>f` (oil) |
| Grep | `<leader>ps` |
| Quick files | `<leader>h` (harpoon) |
| Git status | `<leader>gs` |
| Save | `<leader>s` |

## PR Review Flow

### Automated (runs every 30 min)

1. `pr-review-automation.sh` detects assigned PRs
2. Creates worktree + tmux session
3. Runs Claude review
4. Sends notification

### Manual

1. `Cmd+Shift+S` in Obsidian to sync PRs
2. Open Dashboard, click PR
3. `Cmd+Shift+T` to open in worktree + tmux
4. Review with Claude assistance
5. Submit review on GitHub

### Switching Between PRs

```bash
# In tmux
prefix+k  # Opens session picker
# Select: dcodeit-i360-pr-5156
```

## Task Capture

### Quick Add

1. `Cmd+Shift+A` in Obsidian
2. Type task title
3. Defaults auto-filled
4. Task in inbox

### Process Later

1. Open Dashboard
2. Review Task Inbox section
3. Move to Next Steps or mark done

## Claude Code Sessions

### Start New

```bash
# From project directory
claude

# Or from Obsidian: Cmd+Shift+O
```

### Resume Previous

```bash
claude --resume
```

### Monitor Usage

```bash
ccusage           # Terminal dashboard
ccusage --weekly  # Weekly breakdown
```

## End of Day

### Check Status

```bash
# PR dashboard
prefix+g

# Or in nvim
<leader>pc  # My open PRs
<leader>pr  # PRs needing review
```

### Cleanup

```bash
# Close merged PR sessions
pr-review-automation.sh cleanup
```

## Key Shortcuts Summary

### Shell (zsh)

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | tmux-sessionizer |
| `ccusage` | Claude usage |
| `lg` | lazygit |

### Tmux

| Shortcut | Action |
|----------|--------|
| `prefix+f` | Project finder |
| `prefix+k` | Session picker |
| `prefix+g` | PR dashboard |
| `Alt+Arrow` | Pane navigation |

### Neovim

| Shortcut | Action |
|----------|--------|
| `<leader>f` | File browser |
| `<leader>e` | Find files |
| `<leader>gs` | Git status |
| `<leader>s` | Save |
| `<leader>h` | Harpoon menu |

### Obsidian

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+S` | Sync PRs |
| `Cmd+Shift+O` | Open Claude Code |
| `Cmd+Shift+T` | Review PR in tmux |
| `Cmd+Shift+A` | Add task |
| `Cmd+Shift+G` | Open PR in GitHub |

## Typical Day

```
09:00  Ctrl+F → select project → tmux session
09:05  Check Obsidian Dashboard for PRs
09:10  prefix+g → review assigned PRs
       Each PR in isolated worktree
12:00  Cmd+Shift+A → capture task ideas
14:00  Back to main work session
       <leader>h → harpoon to key files
17:00  ccusage → check Claude budget
       pr-review-automation.sh cleanup
```
