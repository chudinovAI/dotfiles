#!/usr/bin/env bash
set -euo pipefail

# Extend PATH so freshly installed user-local binaries (e.g. starship) are visible.
if [ -d "$HOME/.cargo/bin" ]; then
  PATH="$HOME/.cargo/bin:$PATH"
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FISH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fish"

PM=""
APT_UPDATED=0
IS_ROOT=0
SUDO_CMD=""

log() {
  printf '==> %s\n' "$*"
}

warn() {
  printf '==> WARN: %s\n' "$*" >&2
}

err() {
  printf '==> ERROR: %s\n' "$*" >&2
}

init_privileges() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    IS_ROOT=1
  else
    IS_ROOT=0
  fi

  if [ "$IS_ROOT" -eq 0 ] && command -v sudo >/dev/null 2>&1; then
    SUDO_CMD="sudo"
  fi
}

detect_package_manager() {
  if command -v brew >/dev/null 2>&1; then
    PM="brew"
  elif command -v apt-get >/dev/null 2>&1; then
    PM="apt"
  elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
  elif command -v pacman >/dev/null 2>&1; then
    PM="pacman"
  elif command -v yum >/dev/null 2>&1; then
    PM="yum"
  elif command -v zypper >/dev/null 2>&1; then
    PM="zypper"
  elif command -v yay >/dev/null 2>&1; then
    PM="yay"
  else
    PM=""
  fi

  if [ -n "$PM" ]; then
    log "Detected package manager: $PM"
  else
    warn "No supported package manager detected; automatic package installation may fail."
  fi
}

require_privileged_pm() {
  if [ "$IS_ROOT" -eq 1 ] || [ -n "$SUDO_CMD" ]; then
    return 0
  fi

  err "Package manager '$PM' requires elevated privileges, but sudo is unavailable."
  return 1
}

install_pkg() {
  local pkg="$1"

  case "$PM" in
    brew)
      if ! brew list --versions "$pkg" >/dev/null 2>&1; then
        if ! brew install "$pkg"; then
          return 1
        fi
      fi
      ;;
    apt)
      require_privileged_pm || return 1
      if [ "$APT_UPDATED" -eq 0 ]; then
        if ! $SUDO_CMD apt-get update; then
          return 1
        fi
        APT_UPDATED=1
      fi
      if ! DEBIAN_FRONTEND=noninteractive $SUDO_CMD apt-get install -y "$pkg"; then
        return 1
      fi
      ;;
    dnf)
      require_privileged_pm || return 1
      if ! $SUDO_CMD dnf install -y "$pkg"; then
        return 1
      fi
      ;;
    yum)
      require_privileged_pm || return 1
      if ! $SUDO_CMD yum install -y "$pkg"; then
        return 1
      fi
      ;;
    pacman)
      require_privileged_pm || return 1
      if ! $SUDO_CMD pacman -Sy --noconfirm "$pkg"; then
        return 1
      fi
      ;;
    zypper)
      require_privileged_pm || return 1
      if ! $SUDO_CMD zypper install -y "$pkg"; then
        return 1
      fi
      ;;
    yay)
      if ! yay -S --needed --noconfirm "$pkg"; then
        return 1
      fi
      ;;
    *)
      warn "Cannot install package '$pkg' automatically; unsupported package manager."
      return 1
      ;;
  esac
}

ensure_command() {
  local cmd="$1"
  local pkg="${2:-$1}"

  if command -v "$cmd" >/dev/null 2>&1; then
    log "$cmd is already available."
    return 0
  fi

  if [ -n "$PM" ]; then
    log "Attempting to install $pkg (provides $cmd) via $PM."
    if install_pkg "$pkg"; then
      if command -v "$cmd" >/dev/null 2>&1; then
        log "$cmd installed successfully."
        return 0
      fi
    else
      warn "Installation of $pkg via $PM failed."
    fi
  else
    warn "No package manager available to install $pkg."
  fi

  if command -v "$cmd" >/dev/null 2>&1; then
    log "$cmd is available after installation attempt."
    return 0
  fi

  err "$cmd is still missing. Install package '$pkg' manually and re-run this script."
  return 1
}

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    log "starship is already installed."
    return 0
  fi

  if [ -n "$PM" ]; then
    log "Attempting to install starship via $PM."
    if install_pkg "starship"; then
      if command -v starship >/dev/null 2>&1; then
        log "starship installed via $PM."
        return 0
      fi
    else
      warn "Package manager $PM could not install starship."
    fi
  fi

  log "Falling back to the official starship install script."
  if command -v curl >/dev/null 2>&1; then
    if curl -fsSL https://starship.rs/install.sh | sh -s -- -y >/dev/null; then
      if [ -d "$HOME/.cargo/bin" ]; then
        PATH="$HOME/.cargo/bin:$PATH"
      fi
      if command -v starship >/dev/null 2>&1; then
        log "starship installed via official installer."
        return 0
      fi
    else
      warn "Official starship installer failed."
    fi
  else
    warn "curl is unavailable; cannot run starship installer."
  fi

  if command -v starship >/dev/null 2>&1; then
    log "starship is now available."
    return 0
  fi

  err "Failed to install starship automatically."
  return 1
}

backup_existing_config() {
  if [ -d "$FISH_CONFIG_DIR" ] && [ "$(ls -A "$FISH_CONFIG_DIR" 2>/dev/null)" ]; then
    local backup_dir="${FISH_CONFIG_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
    log "Backing up existing fish configuration to $backup_dir"
    mkdir -p "$(dirname "$backup_dir")"
    cp -a "$FISH_CONFIG_DIR" "$backup_dir"
  fi
}

sync_config_files() {
  log "Syncing fish configuration to $FISH_CONFIG_DIR"
  mkdir -p "$FISH_CONFIG_DIR"

  if command -v rsync >/dev/null 2>&1; then
    rsync -a --exclude "install.sh" "$REPO_DIR/" "$FISH_CONFIG_DIR/"
  else
    warn "rsync not found; falling back to cp for configuration sync."
    shopt -s dotglob nullglob
    for item in "$REPO_DIR"/* "$REPO_DIR"/.*; do
      local name
      name="$(basename "$item")"
      if [ "$name" = "." ] || [ "$name" = ".." ] || [ "$name" = "install.sh" ]; then
        continue
      fi
      rm -rf "$FISH_CONFIG_DIR/$name"
      cp -R "$item" "$FISH_CONFIG_DIR/"
    done
    shopt -u dotglob nullglob
  fi
}

install_fisher() {
  log "Ensuring fisher (fish plugin manager) is installed."
  if fish -c 'functions -q fisher' >/dev/null 2>&1; then
    log "fisher already present."
    return 0
  fi

  if fish -c 'curl -sL https://git.io/fisher | source; and fisher install jorgebucaran/fisher' >/dev/null; then
    log "fisher installed successfully."
  else
    err "Failed to install fisher."
    return 1
  fi
}

install_fisher_plugins() {
  log "Installing fisher plugins defined in fish_plugins."
  if fish -c 'fisher update' >/dev/null; then
    log "fisher plugins installed/updated."
  else
    err "Failed to install fisher plugins."
    return 1
  fi
}

main() {
  init_privileges
  detect_package_manager

  ensure_command "curl" "curl"
  ensure_command "git" "git"

  ensure_command "fish" "fish"

  install_starship

  if ! ensure_command "fzf" "fzf"; then
    warn "fzf is required by the fzf.fish plugin; install it manually if necessary."
  fi

  if ! ensure_command "zoxide" "zoxide"; then
    warn "zoxide enhances directory navigation; install it manually if desired."
  fi

  backup_existing_config
  sync_config_files

  install_fisher
  install_fisher_plugins

  log "Fish configuration installation complete."
  log "Launch fish to start using the new configuration."
}

main "$@"
