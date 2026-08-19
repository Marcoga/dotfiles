#!/usr/bin/env bash
#
# migrate-from-rootstow.sh — repair a home directory where the dotfiles repo
# ROOT was stowed as a package (the laptop, May 2025). Symptoms:
#   ~/.local -> dotfiles/bin/.local      (so ~/.local/share, nvim data, claude
#                                         versions ... live INSIDE the repo)
#   ~/bin ~/zsh ~/tmux ~/git ~/install ~/ubuntu ~/.nvmrc ... -> dotfiles/*
#   ~/.config/nvim -> ../dotfiles/.config/nvim   (pre-rename path)
#
# Dry-run by default: prints what it would do. Pass --apply to do it.
# Afterwards run ./install.sh (it refuses to run while the damage is present).
set -euo pipefail
DOTFILES="${DOTFILES:-$HOME/dotfiles}"
APPLY=0; [[ "${1:-}" == "--apply" ]] && APPLY=1
run() { if [[ $APPLY -eq 1 ]]; then echo "+ $*"; "$@"; else echo "would: $*"; fi; }

echo "repo: $DOTFILES   mode: $([[ $APPLY -eq 1 ]] && echo APPLY || echo DRY-RUN)"
cd "$HOME"

# 1. ~/.local: turn the symlink back into a real directory and MOVE the data
#    (share/, state/, bin/ entries that are not repo files) out of the repo.
if [[ -L "$HOME/.local" ]]; then
  src="$(cd "$HOME/.local" && pwd -P)"          # .../dotfiles/bin/.local
  echo "~/.local is a symlink -> $src"
  run rm "$HOME/.local"
  run mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.local/state"
  for sub in share state; do
    if [[ -d "$src/$sub" ]]; then
      # move contents (these are untracked in git) — same filesystem, so instant
      for item in "$src/$sub"/* "$src/$sub"/.[!.]*; do
        [[ -e "$item" ]] || continue
        run mv "$item" "$HOME/.local/$sub/"
      done
      run rmdir "$src/$sub" || true
    fi
  done
  # bin: real files that are NOT tracked by git are machine-local (claude, prd, task-add ...)
  if [[ -d "$src/bin" ]]; then
    for item in "$src/bin"/*; do
      [[ -e "$item" || -L "$item" ]] || continue
      rel="${item#"$DOTFILES"/}"
      if git -C "$DOTFILES" ls-files --error-unmatch "$rel" >/dev/null 2>&1; then
        continue   # tracked: stow will link it
      fi
      run mv "$item" "$HOME/.local/bin/"
    done
  fi
fi

# 2. Stray top-level symlinks created by stowing the repo root.
for name in bin zsh tmux git nvim config launchd install ubuntu skhd yabai docs .nvmrc .luarc.json .gitignore .DS_Store my-setup bootstrap install.sh README.md CLAUDE.md; do
  p="$HOME/$name"
  if [[ -L "$p" ]] && [[ "$(readlink "$p")" == dotfiles/* ]]; then
    run rm "$p"
  fi
done

# 3. ~/.config/nvim pointing at the pre-rename path (or dangling).
if [[ -L "$HOME/.config/nvim" ]]; then
  dest="$(readlink "$HOME/.config/nvim")"
  if [[ "$dest" == *"dotfiles/.config/nvim"* ]] || [[ ! -e "$HOME/.config/nvim" ]]; then
    run rm "$HOME/.config/nvim"
  fi
fi

# 4. The old-path nvim config inside the repo, if the working tree still has it
#    (the repo moved it to nvim/.config/nvim). Uncommitted edits there are
#    already captured upstream (commit "Capture the laptop's working tree").
if [[ -d "$DOTFILES/.config/nvim" ]]; then
  echo "note: $DOTFILES/.config/nvim still exists in the working tree; 'git pull' / 'git checkout master' will remove it."
fi

echo
if [[ $APPLY -eq 1 ]]; then
  echo "done. Now: cd $DOTFILES && git stash -u (or commit) && git pull && ./install.sh"
else
  echo "dry-run only. Re-run with --apply to execute."
fi
