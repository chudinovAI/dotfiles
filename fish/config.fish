set -U fish_greeting ""
source ~/.config/fish/aliases.fish
starship init fish | source

# Hermes Agent command
fish_add_path "$HOME/.local/bin"
