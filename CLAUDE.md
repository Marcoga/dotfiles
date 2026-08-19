# CLAUDE.md

Marco's dotfiles: zsh + tmux + neovim + git, managed with GNU stow, installed by `install.sh`.

## Layout
- One stow package per tool: `zsh/`, `tmux/`, `nvim/`, `git/`, `bin/`, `config/`, `launchd/` (opt-in).
  Each mirrors `$HOME` (e.g. `bin/.local/bin/x` → `~/.local/bin/x`, `nvim/.config/nvim` → `~/.config/nvim`).
- `install.sh` + `bootstrap/{common,macos,linux}.sh` + `bootstrap/Brewfile` = the reproducible install. Idempotent; bash 3.2 compatible (macOS stock bash).
- `bin/.local/bin/dotfiles-doctor` prints link/tool/shell/nvim state.
- `docs/my-setup/` = workflow documentation.

## Rules
- Never add a top-level file that stow would link into `$HOME`; repo-level files (README, install.sh, bootstrap/, docs/) are fine because only the listed packages are stowed.
- Never stow the repo root. Never run `stow` without `-d $DOTFILES -t $HOME`.
- No secrets, ever (public repo). Keys → `~/.secrets`; machine paths → `~/.zshrc.local` / `~/.gitconfig.local`.
- `zsh/.zshrc` must keep the line `managed by ~/dotfiles` (the doctor checks it to detect installer overwrites).
- nvim: `lua/options.lua` must not `require` plugins — lazy.nvim bootstraps in `lua/lazy_init.lua`; colorscheme is set there after `setup()`.
- Test changes with `./install.sh --only-link` then `dotfiles-doctor`; for the full path use a Lima Ubuntu VM (`limactl start template://ubuntu-lts`).
- Commits: no Co-Authored-By trailers.
