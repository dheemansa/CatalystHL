if status is-interactive
    # Commands to run in interactive sessions can go here

    set -Ux EDITOR nvim

    starship init fish | source
    set fish_greeting
    set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml


    # Fix cursor shape in Alacritty terminal: Resets to Beam
    # Vim/SSH leave the cursor as block on exit
    # Comment this function if you change the cursor shape in Alacritty
    function fix_cursor --on-event fish_prompt
        printf '\033[6 q'
    end

    zoxide init fish | source

    # Set up fzf key bindings
    fzf --fish | source

    # Centralized list of files/directories to exclude from fzf
    set -l fzf_excludes ".config/BraveSoftware" ".config/chromium" ".local" ".cache" ".cargo" ".git" ".idea" ".rustup" ".vscode" "__pycache__" "build" "dist" "node_modules" "target" "temp" "tmp" "venv"

    if type -q fd
        # Use fd for faster search, applying excludes
        set -l exclude_args (printf ' --exclude %s' $fzf_excludes)
        set -gx FZF_DEFAULT_COMMAND "fd --hidden$exclude_args"
        set -gx FZF_CTRL_T_COMMAND "fd --ignore-file .gitignore --no-ignore --hidden$exclude_args" # this will not hide the git-exclude files
        set -gx FZF_ALT_C_COMMAND "fd --type d --hidden$exclude_args"
    else
        # Fallback to find if fd is not available
        set -l find_excludes_list
        for i in $fzf_excludes
            set -a find_excludes_list "-path './$i'"
            set -a find_excludes_list "-o"
        end
        if test (count $find_excludes_list) -gt 0
            set -e find_excludes_list[-1] # Remove trailing -o
        end

        set -gx FZF_DEFAULT_COMMAND "find . \( $find_excludes_list \) -prune -o -print"
        set -gx FZF_CTRL_T_COMMAND "find . \( $find_excludes_list \) -prune -o -print"
        set -gx FZF_ALT_C_COMMAND "find . \( $find_excludes_list \) -prune -o -type d -print"
    end
    
    alias update-grub="sudo grub-mkconfig -o /boot/grub/grub.cfg"
    
    alias wc="wl-copy"

    fish_add_path $HOME/.local/bin

    # load luminol colors
    if test -f $HOME/.cache/luminol/sequence
        cat $HOME/.cache/luminol/sequence
    else
        echo "Failed to load luminol colors"
    end

    set -Ux PYENV_ROOT $HOME/.pyenv
    set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths

    # Load pyenv 
    pyenv init - fish | source

end
