# Zsh Configuration

Config: `~/.zshrc` (stowed from `~/dotfiles/zsh/.zshrc`)

## Framework

**oh-my-zsh** with `robbyrussell` theme

## Plugins

| Plugin | Purpose |
|--------|---------|
| `git` | Git aliases and completions |
| `zsh-autosuggestions` | Fish-like autosuggestions |
| `vi-mode` | Vim keybindings in shell |
| `zsh-nvm` | Lazy-load nvm for Node.js |
| `zsh-syntax-highlighting` | Command syntax highlighting |

## Vi Mode

```zsh
bindkey -v
VI_MODE_RESET_PROMPT_ON_MODE_CHANGE=true
VI_MODE_SET_CURSOR=true
MODE_INDICATOR="%F{yellow}+%f"
```

## Key Bindings

| Keybinding | Action |
|------------|--------|
| `Ctrl+F` | Launch `tmux-sessionizer` |

## Aliases

### Editor
| Alias | Command |
|-------|---------|
| `vim`, `vi` | `nvim` |
| `oldvim` | Original `vim` |

### Tools
| Alias | Command |
|-------|---------|
| `lg` | `lazygit` |
| `pn` | `pnpm` |
| `av` | `ansible-vault` |
| `sr` | `omz reload` |

### Config
| Alias | Command |
|-------|---------|
| `zshconfig`, `zconf` | `vim ~/.zshrc` |

### Claude Code Usage
| Alias | Command |
|-------|---------|
| `claude-usage` | `~/scripts/claude-usage.sh` |
| `claude-usage-update` | `~/scripts/claude-usage-obsidian.sh` |

### Git (project-specific)
| Alias | Command |
|-------|---------|
| `nov` | `git co release/22.11` |
| `may` | `git co release/23.05` |
| `cleanbr` | Delete non-release branches |

## PATH

```zsh
$HOME/scripts
$HOME/bin
$HOME/.local/bin
/opt/homebrew/bin
$(npm bin -g)
```

## Auto-load .nvmrc

Automatically switches Node version when entering directory with `.nvmrc`:

```zsh
add-zsh-hook chpwd load-nvmrc
```

## Dependencies

- oh-my-zsh
- nvm (Node Version Manager)
- Homebrew (for /opt/homebrew/bin)
