# dotfiles

My zsh + tmux + neovim + git setup, managed with [GNU stow](https://www.gnu.org/software/stow/).
Works on macOS and Debian/Ubuntu.

## New machine

```bash
git clone https://github.com/Marcoga/dotfiles.git ~/dotfiles
~/dotfiles/install.sh
```

That is the whole procedure. `install.sh` detects the OS and:

1. installs the tools — macOS: Homebrew + [`bootstrap/Brewfile`](bootstrap/Brewfile);
   Debian/Ubuntu: apt + neovim/lazygit/gitmux from GitHub releases into `~/.local/bin`
2. installs oh-my-zsh (without touching `.zshrc`), the custom plugins
   (zsh-autosuggestions, zsh-syntax-highlighting, zsh-nvm) and nvm + node LTS
3. stows the packages `zsh tmux nvim git bin config` into `$HOME`
   (real files in the way are moved to `~/.dotfiles-backup/<timestamp>/`)
4. creates `~/.secrets`, `~/.zshrc.local`, `~/.gitconfig.local` if absent (machine-local, never in git)
5. makes zsh the login shell, installs a Nerd Font, runs `Lazy! sync` + Mason tools for neovim
6. prints `dotfiles-doctor`

Re-run it any time (after `git pull`) — it is idempotent. Flags: `--no-packages`, `--no-nvim`,
`--only-link`, `--with launchd`, `--packages "zsh tmux"`.

Then put your API keys in `~/.secrets` (e.g. `ANTHROPIC_API_KEY` for avante.nvim) and open a new terminal.

## Layout

| Package | Stowed to | What |
|---|---|---|
| `zsh/` | `~/.zshrc` | oh-my-zsh, vi-mode, zsh-nvm + `.nvmrc` auto-switch, aliases, `Ctrl-F` → tmux-sessionizer |
| `tmux/` | `~/.tmux.conf` | prefix `C-a`, vi copy-mode to the system clipboard (pbcopy / wl-copy / xclip), `prefix f/k/y` session helpers, gitmux status |
| `nvim/` | `~/.config/nvim/` | lazy.nvim config — see [docs/my-setup/tools/nvim.md](docs/my-setup/tools/nvim.md) |
| `git/` | `~/.gitconfig` | identity, aliases; includes `~/.gitconfig.local` |
| `bin/` | `~/.local/bin/*` | `tmux-sessionizer`, `tmux-session-picker`, `tmux-window-opener`, `dotfiles-doctor`, pr-review scripts |
| `config/` | `~/.config/pr-review/` | pr-review automation config |
| `launchd/` | `~/Library/LaunchAgents/` | macOS agent for pr-review (opt-in: `--with launchd`) |

Machine-specific things live outside the repo and are sourced/included if present:
`~/.secrets` (keys), `~/.zshrc.local` (extra PATH, host aliases), `~/.gitconfig.local`.

## Rules that keep this working

- **Never stow the repo root** (`stow dotfiles` from `~`, or `stow .`). That symlinks `~/.local`
  and `~/bin` into the repo and every tool starts writing its data inside the checkout.
  `install.sh` always runs `stow -d ~/dotfiles -t ~ <package>` and pre-creates
  `~/.local/{bin,share,state}` and `~/.config` so stow never folds them.
  If a machine already has that damage, `bootstrap/migrate-from-rootstow.sh` repairs it (dry-run by default).
- **Installers that "add themselves to .zshrc"** (oh-my-zsh, nvm, deno, …) write through the symlink
  into `zsh/.zshrc`. `install.sh` runs them with the keep-my-rc flags; if something does sneak in,
  `git diff zsh/.zshrc` shows it — move the line to `~/.zshrc.local` and `git checkout zsh/.zshrc`.
- Secrets never go in the repo (it is public). `~/.secrets` is `chmod 600` and gitignored by being outside.
- Edit configs through the symlinks (`vim ~/.zshrc`, `~/.config/nvim/...`) — they *are* the repo files; commit from `~/dotfiles`.

## Docs

`docs/my-setup/` documents the whole workflow (tmux, zsh, nvim keymaps, git, Claude Code, PR review, Obsidian).
