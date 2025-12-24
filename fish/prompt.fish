starship init fish | source
function fish_mode_prompt
    switch $fish_bind_mode
        case default
            set_color green --bold
            echo '[N] '
        case insert
            set_color brblack --bold
            echo '[I] '
        case visual
            set_color green --bold
            echo '[V] '
        case replace_one
            set_color green --bold
            echo '[R] '
    end
    set_color normal
end
