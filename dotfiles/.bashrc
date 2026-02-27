# ~/.bashrc


# fallback mechanism which will use bash when fish is not available

# Only run in interactive shells
if [[ $- == *i* ]]; then
    # Avoid recursion if already in fish
    if [ -z "$FISH_VERSION" ]; then
        # Only exec fish if the shell is not explicitly bash
        if [[ -z "$BASH_EXEC_STARTED" ]]; then
            if command -v fish >/dev/null 2>&1; then
                export BASH_EXEC_STARTED=1
                exec fish
            fi
        fi
    fi
fi

# Your usual bash settings
alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
