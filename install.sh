#!/usr/bin/env bash
# Symlink dotfiles into place. Safe to re-run: existing files are moved to
# ~/.dotfiles-backup/<timestamp>/ before being replaced.
#
#   ./install.sh            # this machine (macOS or Linux desktop)
#   ./install.sh --brew     # + install everything from Brewfile (macOS)
#   ./install.sh --server   # headless VPS: fish, starship, tmux, bash -> fish
#   ./install.sh --jupyter  # + Python kernel with pandas for Zed notebooks/REPL
#   ./install.sh --dry-run  # show what would happen, change nothing
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
SERVER=0 BREW=0 DRY=0 JUPYTER=0

for arg in "$@"; do
  case "$arg" in
    --server)  SERVER=1 ;;
    --brew)    BREW=1 ;;
    --jupyter) JUPYTER=1 ;;
    --dry-run) DRY=1 ;;
    -h|--help) sed -n '2,10p' "$0"; exit 0 ;;
    *) echo "unknown option: $arg" >&2; exit 1 ;;
  esac
done

run() { if [ "$DRY" = 1 ]; then echo "  would: $*"; else "$@"; fi; }

# link <file in repo> <target path>
link() {
  local src="$DOTFILES/$1" dst="$2"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "ok      $dst"; return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    echo "backup  $dst"
    run mkdir -p "$BACKUP/$(dirname "${dst#"$HOME"/}")"
    run mv "$dst" "$BACKUP/${dst#"$HOME"/}"
  fi
  echo "link    $dst -> $1"
  run mkdir -p "$(dirname "$dst")"
  run ln -s "$src" "$dst"
}

# copy_once <file in repo> <target path>
# For configs the app rewrites itself with machine-local data (Zed stores SSH
# hosts in settings.json): a symlink would leak them into this public repo.
copy_once() {
  local src="$DOTFILES/$1" dst="$2"
  if [ ! -e "$dst" ]; then
    echo "copy    $dst <- $1"
    run mkdir -p "$(dirname "$dst")"
    run cp "$src" "$dst"
  elif ! cmp -s "$src" "$dst"; then
    echo "differs $dst (kept local copy; compare: diff $src $dst)"
  else
    echo "ok      $dst"
  fi
}

# --- shared: fish + starship ------------------------------------------------
link fish/config.fish         "$HOME/.config/fish/config.fish"
link fish/aliases.fish        "$HOME/.config/fish/aliases.fish"
link fish/conf.d/uv.env.fish  "$HOME/.config/fish/conf.d/uv.env.fish"
link starship.toml            "$HOME/.config/starship.toml"

if [ "$SERVER" = 1 ]; then
  # --- VPS -------------------------------------------------------------------
  link server/tmux.conf "$HOME/.config/tmux/tmux.conf"

  # Keep bash as the login shell (apps over SSH need POSIX), switch only
  # interactive terminals to fish; ~/.local/bin must be on PATH before the
  # "not interactive -> return" guard of Debian's .bashrc.
  if ! grep -q "exec fish" "$HOME/.bashrc" 2>/dev/null; then
    echo "patch   ~/.bashrc (PATH + exec fish for interactive shells)"
    if [ "$DRY" = 0 ]; then
      tmp="$(mktemp)"
      { printf '# PATH for non-interactive SSH (Desktop apps) — must be above the interactive guard\nexport PATH="$HOME/.local/bin:$PATH"\n\n'
        cat "$HOME/.bashrc" 2>/dev/null || true
        cat <<'EOF'

# Interactive SSH sessions → fish; non-interactive commands (apps, scripts) stay in bash
if [[ $- == *i* && -z "$BASH_EXECUTION_STRING" && -z "$NO_FISH" ]] && command -v fish >/dev/null \
   && [[ "$(ps -o comm= -p $PPID)" != fish ]]; then
  exec fish
fi
EOF
      } > "$tmp" && mv "$tmp" "$HOME/.bashrc"
    fi
  else
    echo "ok      ~/.bashrc"
  fi

  for cmd in fish starship eza bat fzf tmux; do
    command -v "$cmd" >/dev/null || command -v "${cmd}cat" >/dev/null \
      || echo "missing $cmd — install it as an admin: sudo apt install fish eza bat fzf tmux (starship: starship.rs)"
  done
  exit 0
fi

# --- desktop: macOS / Linux ---------------------------------------------------
if [ "$(uname)" = Darwin ]; then
  GHOSTTY="$HOME/Library/Application Support/com.mitchellh.ghostty/config.ghostty"
else
  GHOSTTY="$HOME/.config/ghostty/config"
fi
link config.ghostty   "$GHOSTTY"              # cmux reads this one too
link cmux.json        "$HOME/.config/cmux/cmux.json"
link gitconfig        "$HOME/.gitconfig"
link .vimrc           "$HOME/.vimrc"
link nvim             "$HOME/.config/nvim"
link zed/keymap.json  "$HOME/.config/zed/keymap.json"
copy_once zed/settings.json "$HOME/.config/zed/settings.json"
if [ "$(uname)" = Darwin ]; then
  # Unlocks Zed's notebook UI for GUI launches (see the plist); takes effect at next login
  copy_once macos/zed-notebooks.plist "$HOME/Library/LaunchAgents/local.zed-notebooks.plist"
fi

if [ "$BREW" = 1 ]; then
  if command -v brew >/dev/null; then
    echo "brew    bundle --file Brewfile"
    run brew bundle --file "$DOTFILES/Brewfile"
  else
    echo "brew not found: install Homebrew first (https://brew.sh)" >&2
    exit 1
  fi
fi

# --- Jupyter kernel for Zed (.ipynb, REPL in .py) ----------------------------
# One uv env with the usual data stack, registered as the user's "python3"
# kernel: Zed falls back to it outside projects (a project's own .venv still
# wins) and JupyterLab gets pandas too.
if [ "$JUPYTER" = 1 ]; then
  PYDATA="$HOME/.local/share/py-data"
  if command -v uv >/dev/null; then
    echo "jupyter $PYDATA (ipykernel pandas numpy matplotlib)"
    [ -d "$PYDATA" ] || run uv venv --quiet "$PYDATA"
    run uv pip install --quiet --python "$PYDATA" ipykernel pandas numpy matplotlib
    run "$PYDATA/bin/python" -m ipykernel install --user --name python3 --display-name "Python 3 (data)"
  else
    echo "uv not found: run ./install.sh --brew first" >&2
    exit 1
  fi
fi

# --- fish as login shell (macOS) ---------------------------------------------
FISH="$(command -v fish || true)"
if [ "$(uname)" = Darwin ] && [ -n "$FISH" ]; then
  if ! grep -qx "$FISH" /etc/shells; then
    echo "add     $FISH to /etc/shells (sudo)"
    run sudo sh -c "echo '$FISH' >> /etc/shells"
  fi
  if [ "$(dscl . -read "$HOME" UserShell | awk '{print $2}')" != "$FISH" ]; then
    echo "chsh    $FISH"
    run chsh -s "$FISH"
  else
    echo "ok      login shell $FISH"
  fi
fi

[ -d "$BACKUP" ] && echo "backups in $BACKUP"
echo "done"
