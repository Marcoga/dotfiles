# My Setup

Documentation for the integrated development environment: tmux + zsh + nvim + Obsidian + Claude Code.

## Quick Start

```bash
# Install dotfiles
cd ~/dotfiles
./install

# Dependencies
brew install neovim tmux fzf ripgrep fd lazygit gh gitmux terminal-notifier

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/lukechilds/zsh-nvm ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-nvm
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Terminal                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                      tmux                              │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │  │
│  │  │   nvim      │  │   shell     │  │  Claude     │   │  │
│  │  │             │  │   (zsh)     │  │   Code      │   │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘   │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│    Git      │      │   GitHub    │      │  Obsidian   │
│  worktrees  │ ←──→ │    PRs      │ ←──→ │   vault     │
└─────────────┘      └─────────────┘      └─────────────┘
```

## Tools

| Tool | Config | Doc |
|------|--------|-----|
| tmux | `~/.tmux.conf` | [tools/tmux.md](tools/tmux.md) |
| zsh | `~/.zshrc` | [tools/zsh.md](tools/zsh.md) |
| nvim | `~/.config/nvim/` | [tools/nvim.md](tools/nvim.md) |
| git | `~/.gitconfig` | [tools/git.md](tools/git.md) |
| Claude Code | Various | [tools/claude-code.md](tools/claude-code.md) |

## Workflows

| Workflow | Doc |
|----------|-----|
| PR Review | [workflows/pr-review.md](workflows/pr-review.md) |
| Task Inbox | [workflows/task-inbox.md](workflows/task-inbox.md) |
| Daily Workflow | [workflows/daily-workflow.md](workflows/daily-workflow.md) |

## Scripts

See [scripts/inventory.md](scripts/inventory.md) for full list.

Key scripts:
- `tmux-sessionizer` - Fuzzy project finder
- `pr-review-automation.sh` - PR review orchestrator
- `pr-dashboard.sh` - Terminal PR browser
- `claude-usage.sh` - Token usage monitoring

## Key Shortcuts

### Everywhere

| Shortcut | Action |
|----------|--------|
| `Ctrl+F` | tmux-sessionizer (find project) |
| `Ctrl+A` | tmux prefix |

### tmux

| Shortcut | Action |
|----------|--------|
| `prefix+f` | Project finder |
| `prefix+k` | Session picker |
| `prefix+g` | PR dashboard |

### nvim

| Shortcut | Action |
|----------|--------|
| `<space>f` | File browser |
| `<space>e` | Find files |
| `<space>gs` | Git status |

### Obsidian

| Shortcut | Action |
|----------|--------|
| `Cmd+Shift+S` | Sync PRs |
| `Cmd+Shift+T` | Review PR |
| `Cmd+Shift+A` | Add task |

## Directory Structure

```
~/
├── dotfiles/           # This repo (stow-managed)
│   ├── .config/nvim/   # Neovim config
│   ├── tmux/           # Tmux config
│   ├── zsh/            # Zsh config
│   ├── git/            # Git config
│   ├── bin/.local/bin/ # Scripts
│   └── my-setup/       # This documentation
├── scripts/            # Additional scripts
├── obsidian-vault/     # Knowledge base
│   ├── PRs/            # PR tracking
│   ├── Inbox/          # Task inbox
│   └── Plans/          # Project plans
└── work/               # Projects
    └── i360/
        ├── main/       # Main branch
        └── pr-*/       # PR worktrees
```

## Stow Installation

The dotfiles use GNU stow to create symlinks:

```bash
cd ~/dotfiles
stow bin config git launchd tmux zsh
```

Or use the install script:

```bash
./install
```
