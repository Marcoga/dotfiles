# Git Configuration

Config: `~/.gitconfig` (stowed from `~/dotfiles/git/.gitconfig`)

## User

```
Marco Garcia <marco.gar7@gmail.com>
```

## Aliases

### Basic

| Alias | Command |
|-------|---------|
| `co` | `checkout` |
| `st` | `status` |
| `ci` | `commit` |
| `br` | `branch` |

### Remote Operations

| Alias | Command | Description |
|-------|---------|-------------|
| `pullre` | `pull --recurse-submodules` | Pull with submodules |
| `pusht` | `push --follow-tags` | Push with tags |
| `cloner` | `clone --recurse-submodules` | Clone with submodules |

### Submodule Management

| Alias | Command | Description |
|-------|---------|-------------|
| `subadd <name>` | Add submodule | Adds `dcodeit/<name>` to `./src/packages/<name>` |
| `subdel <name>` | Delete submodule | Deinit and remove |
| `subupd <name>` | Update one | Update specific submodule |
| `subupda` | Update all | `submodule update --init --recursive` |
| `subupgr <name>` | Upgrade | Update remote and merge |

## Settings

| Setting | Value |
|---------|-------|
| LFS | Enabled |
| Pull | No rebase (merge) |
| Push | Auto-setup remote |

## Worktree Workflow

Used for PR reviews - each PR gets its own worktree:

```
~/work/i360/
├── main/           # Main branch (always on master)
├── pr-5156/        # Worktree for PR #5156
├── pr-5168/        # Worktree for PR #5168
└── pr-{number}/    # Pattern
```

### Create worktree for PR

```bash
cd ~/work/i360/main
git fetch origin pull/5156/head:pr-5156
git worktree add ../pr-5156 pr-5156
```

### Remove worktree

```bash
git worktree remove ../pr-5156
git branch -D pr-5156
```

This is automated by `pr-review-automation.sh`.

## Maintenance

```ini
[maintenance]
    repo = /Users/mgarcia/work/i360
```

Git maintenance is configured to run on the main work repo.

## LFS (Large File Storage)

```ini
[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true
```

## Dependencies

- git-lfs
- GitHub CLI (`gh`) for PR operations
