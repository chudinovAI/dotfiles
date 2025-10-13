if type -q starship
    starship init fish | source
end

if type -q zoxide
    zoxide init fish | source
end

if type -q fzf
    if test -f /usr/share/fzf/completion.fish
        source /usr/share/fzf/completion.fish
    end
end
