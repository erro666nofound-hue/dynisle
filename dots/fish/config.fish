# Programs installed per user (Claude Code's own installer, pip --user...) live
# in ~/.local/bin. This machine got it onto PATH from ~/.profile, which is not
# carried to other machines - so fish adds it itself. Skipped if it does not
# exist yet; never added twice.
fish_add_path -g ~/.local/bin

# Commands to run in interactive sessions can go here
if status is-interactive
    # No greeting
    set fish_greeting

    # dynisle: the black hole greeting on every new terminal - hardware left,
    # software right. scripts/fetch.py lays it out (and adapts to narrow
    # windows); fastfetch finds the facts. It sat in ~/.zshrc before and never
    # ran, because kitty and foot both start FISH, not zsh.
    if test "$TERM" != "linux"; and command -q fastfetch
        set -l greet ~/.config/quickshell/dynisle/scripts/fetch.py
        if test -f $greet
            python3 $greet
        else
            fastfetch
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
