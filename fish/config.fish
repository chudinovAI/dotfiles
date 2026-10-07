# Homebrew on PATH: fish as login shell does not inherit it from zsh
test -x /opt/homebrew/bin/brew; and /opt/homebrew/bin/brew shellenv fish | source

set -U fish_greeting ""
source ~/.config/fish/aliases.fish
starship init fish | source

# Hermes Agent command
fish_add_path "$HOME/.local/bin"
