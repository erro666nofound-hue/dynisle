# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # dynisle: the black hole on every new terminal. It sat in ~/.zshrc before
    # and never ran, because kitty and foot both start FISH, not zsh.
    # The black hole and the table need 106 columns side by side; in a
    # narrower window only the table is shown, so nothing wraps and breaks.
    if test "$TERM" != "linux"; and command -q fastfetch
        if test $COLUMNS -ge 106
            fastfetch
        else
            fastfetch --logo none
        end
    end

    # Use starship
    function starship_transient_prompt_func
        starship module character
    end
    if test "$TERM" != "linux"
        starship init fish | source
        enable_transience
    end
    
    # Colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    # kitty doesn't clear properly so we need to do this weird printing
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    if test "$TERM" != "linux"
        alias ls 'eza --icons=auto'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end
