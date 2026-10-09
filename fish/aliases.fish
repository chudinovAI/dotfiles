alias ls="eza -lh --group-directories-first --icons=auto"
alias lsa="ls -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias lta="lt -a"
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"

# Keyboard cheatsheet for Zed + cmux: rendered viewer inside cmux, plain text elsewhere
function cheat
    set -l f ~/dotfiles/CHEATSHEET.md
    command -q cmux; and cmux markdown open $f 2>/dev/null; or bat --style=plain $f
end
