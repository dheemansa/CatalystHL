if status is-interactive
    # Commands to run in interactive sessions can go here
end

#####################################
##==> Shell Customization
#####################################
starship init fish | source
set fish_greeting
set -gx STARSHIP_CONFIG ~/.config/starship/starship.toml
