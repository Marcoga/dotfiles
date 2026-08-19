# Tmux Configuration

Config: `~/.tmux.conf` (stowed from `~/dotfiles/tmux/.tmux.conf`)

## Prefix Key

**`Ctrl+A`** (changed from default `Ctrl+B`)

## Pane Management

| Keybinding | Action |
|------------|--------|
| `prefix + \` | Split horizontally (side by side) |
| `prefix + -` | Split vertically (top/bottom) |
| `Alt + Arrow` | Switch panes (no prefix needed) |
| `prefix + r` | Reload config |

## Copy Mode (Vim-style)

| Keybinding | Action |
|------------|--------|
| `v` | Begin selection |
| `y` | Copy to clipboard |
| `Enter` | Copy and exit |
| `r` | Rectangle toggle |

## Session Helpers

| Keybinding | Script | Description |
|------------|--------|-------------|
| `prefix + f` | `tmux-sessionizer` | Fuzzy-find project, create/attach session |
| `prefix + k` | `tmux-session-picker` | Switch between existing sessions |
| `prefix + y` | `tmux-window-opener` | Open window from subdirectory |
| `prefix + g` | `pr-dashboard.sh` | Terminal PR dashboard (fzf) |

### tmux-sessionizer

Searches directories in order:
1. `~/work/`
2. `~/personal/`
3. `~`

Creates session named after directory (dots → underscores).

Also bound to `Ctrl+F` in zsh for quick access outside tmux.

## Status Bar

- **Position:** Top
- **Left:** Session name + git status via [gitmux](https://github.com/arl/gitmux)
- **Right:** Empty (clean)
- **Colors:** Dark theme (bg: color234)

## Settings

| Setting | Value |
|---------|-------|
| Shell | `/bin/zsh` |
| Mouse | Enabled |
| Mode keys | vi |
| Base index | 1 (windows start at 1, not 0) |
| Terminal | `screen-256color` |

## Dependencies

- `gitmux` - Git status in status bar
- `fzf` - Fuzzy finder for session helpers
- `tmux-sessionizer` - Custom script in `~/.local/bin/`
