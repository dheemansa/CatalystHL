
#!/usr/bin/env sh

# Path to your gamemode script
HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

if [ "$HYPRGAMEMODE" = 1 ]; then
    # Gamemode ON
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword animation borderangle,0; \
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:fullscreen_opacity 1;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword decoration:rounding 0"
        
# Disable all transparency for existing windows
    hyprctl dispatch "opacity 1 class:*"
    # Kill Waybar
    pkill waybar
    
    # Notify
    notify-send -u low -t 5000 "Gamemode [ON]"
else
    # Gamemode OFF
    notify-send -u low -t 5000 "Gamemode [OFF]"
    
    # Reload Hyprland config
    hyprctl reload
    
    # Relaunch Waybar
    waybar &
fi
