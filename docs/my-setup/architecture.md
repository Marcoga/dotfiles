# System Architecture

How all components connect and communicate.

## High-Level Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              TERMINAL LAYER                              │
│  ┌────────────────────────────────────────────────────────────────────┐ │
│  │                            tmux                                     │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────────┐ │ │
│  │  │    nvim      │  │    zsh       │  │    Claude Code           │ │ │
│  │  │  - LSP       │  │  - oh-my-zsh │  │  - /review-pr            │ │ │
│  │  │  - telescope │  │  - vi-mode   │  │  - session tracking      │ │ │
│  │  │  - fugitive  │  │  - nvm       │  │  - token monitoring      │ │ │
│  │  │  - harpoon   │  │              │  │                          │ │ │
│  │  └──────────────┘  └──────────────┘  └──────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                │                │                        │
                ▼                ▼                        ▼
┌───────────────────┐  ┌─────────────────┐  ┌─────────────────────────────┐
│   Git Worktrees   │  │  GitHub (gh)    │  │       Obsidian Vault        │
│                   │  │                 │  │                             │
│ ~/work/i360/      │  │  - PR list      │  │  ~/obsidian-vault/          │
│ ├── main/         │◄─┤  - PR data      │◄─┤  ├── PRs/Dashboard.md       │
│ ├── pr-5156/      │  │  - Reviews      │  │  ├── PRs/authored/          │
│ └── pr-5168/      │  │                 │  │  ├── Inbox/                 │
└───────────────────┘  └─────────────────┘  └─────────────────────────────┘
         ▲                     ▲                        ▲
         │                     │                        │
         └─────────────────────┴────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │  AUTOMATION LAYER   │
                    │                     │
                    │  pr-review-         │
                    │  automation.sh      │
                    │  (LaunchD: 30min)   │
                    └─────────────────────┘
```

## Data Flow

### PR Review Flow

```
1. GitHub PR assigned to @me
         │
         ▼
2. pr-review-automation.sh (scheduled)
         │
         ├──► gh pr list --search "review-requested:@me"
         │
         ▼
3. Creates git worktree
         │
         └──► ~/work/i360/pr-{number}/
         │
         ▼
4. Creates tmux session
         │
         └──► tmux new-session -s "dcodeit-i360-pr-{number}"
         │
         ▼
5. Runs project setup
         │
         └──► ~/.config/pr-review/project-scripts/dcodeit-i360.sh
         │
         ▼
6. Launches Claude Code
         │
         └──► claude /review-pr
         │
         ▼
7. Updates Obsidian note
         │
         └──► ~/obsidian-vault/PRs/reviews/pr-{number}.md
         │
         ▼
8. macOS notification
```

### Task Capture Flow

```
1. Cmd+Shift+A in Obsidian
         │
         ▼
2. task-add-obsidian.sh
         │
         ├──► Analyzes last 5 tasks for defaults
         │
         ▼
3. Creates note in Inbox/
         │
         └──► ~/obsidian-vault/Inbox/task-{date}-{id}.md
         │
         ▼
4. Dashboard Dataview query displays task
```

### Claude Usage Tracking Flow

```
1. Claude Code sessions write to ~/.claude/
         │
         └──► projects/{hash}/{session}.jsonl
         │
         ▼
2. claude-usage.sh reads JSONL files
         │
         ├──► Calculates weighted tokens
         ├──► Compares to budget
         │
         ▼
3. Outputs: terminal, SVG charts, Obsidian reports
```

## Component Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│                         DOTFILES                             │
│  ~/dotfiles/ (stow-managed)                                 │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐    │
│  │ .config/ │  │  tmux/   │  │   zsh/   │  │   git/   │    │
│  │  nvim/   │  │.tmux.conf│  │ .zshrc   │  │.gitconfig│    │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘    │
│       │             │             │             │           │
│       │             │             │             │           │
│  ┌────┴─────────────┴─────────────┴─────────────┴────┐     │
│  │              bin/.local/bin/                       │     │
│  │  - tmux-sessionizer                                │     │
│  │  - tmux-session-picker                             │     │
│  │  - pr-review-automation.sh                         │     │
│  └────────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              │
                    stow symlinks to ~/
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                         HOME (~/)                            │
│                                                              │
│  ~/.config/nvim/ ──────► nvim                               │
│  ~/.tmux.conf ─────────► tmux                               │
│  ~/.zshrc ─────────────► zsh                                │
│  ~/.gitconfig ─────────► git                                │
│  ~/.local/bin/ ────────► PATH                               │
└─────────────────────────────────────────────────────────────┘
```

## External Dependencies

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| neovim | Editor | `brew install neovim` |
| tmux | Terminal multiplexer | `brew install tmux` |
| fzf | Fuzzy finder | `brew install fzf` |
| ripgrep | Fast grep | `brew install ripgrep` |
| fd | Fast find | `brew install fd` |
| gh | GitHub CLI | `brew install gh` |

### Optional

| Tool | Purpose | Install |
|------|---------|---------|
| lazygit | Git TUI | `brew install lazygit` |
| gitmux | Git in tmux status | `brew install gitmux` |
| terminal-notifier | macOS notifications | `brew install terminal-notifier` |

### Services

| Service | Purpose | Config |
|---------|---------|--------|
| LaunchD | Scheduled automation | `~/dotfiles/launchd/com.user.pr-review.plist` |

## Configuration Locations

| Config | Path | Purpose |
|--------|------|---------|
| PR Review | `~/.config/pr-review/config.sh` | Automation settings |
| Project Scripts | `~/.config/pr-review/project-scripts/` | Per-repo setup |
| Claude Usage | `~/.claude-usage-config.json` | Budget, rate limits |
| Claude Data | `~/.claude/` | Session data |
| Obsidian | `~/.obsidian-vault/.obsidian/` | Vault settings |

## Integration Points

### tmux ↔ Scripts

```bash
# .tmux.conf bindings to scripts
bind-key -r f run-shell "~/.local/bin/tmux-sessionizer"
bind-key -r g run-shell "~/scripts/pr-dashboard.sh"
```

### zsh ↔ tmux

```bash
# .zshrc binding
bindkey -s ^f "tmux-sessionizer\n"
```

### Obsidian ↔ Scripts

Shell Commands plugin maps keyboard shortcuts to scripts:
- `Cmd+Shift+S` → `sync-prs-to-obsidian.sh`
- `Cmd+Shift+T` → `review-pr-with-tmux.sh`
- `Cmd+Shift+A` → `task-add-obsidian.sh`

### nvim ↔ GitHub

Octo.nvim plugin queries GitHub directly:
```lua
:Octo search author:@me is:pr is:open
```

### Claude Code ↔ Obsidian

- `CLAUDE_CONTEXT.md` provides context
- PR notes updated with `claude_last_review` timestamp
- Prompt files passed to Claude sessions

## State Storage

| Data | Location | Format |
|------|----------|--------|
| PR session state | `~/.local/state/pr-review/` | Text files |
| Claude sessions | `~/.claude/projects/` | JSONL |
| Claude stats cache | `~/.claude/stats-cache.json` | JSON |
| Obsidian notes | `~/obsidian-vault/` | Markdown + YAML frontmatter |
| Git worktrees | `~/work/*/pr-*` | Git directories |
