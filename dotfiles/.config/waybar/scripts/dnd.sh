#!/bin/bash
# Usage: ./dnd.sh [toggle|status|on|off]

DND_ON_ICON="󱅫"
DND_OFF_ICON="󱏧"

# Function to check if dunst is paused
is_dunst_paused() {
    dunstctl is-paused | grep -q "true"
}

# Function to pause dunst
pause_dunst() {
    #notify-send -u low "Do Not Disturb" "Notifications paused" 2>/dev/null || true
    #sleep 5
    dunstctl set-paused true
}

# Function to unpause dunst
unpause_dunst() {
    dunstctl set-paused false
    notify-send -u low "Do Not Disturb" "Notifications resumed" 2>/dev/null || true
}

# Function to get status for waybar
get_status() {
    if is_dunst_paused; then
        echo "{\"text\":\"$DND_OFF_ICON\",\"tooltip\":\"Do Not Disturb: OFF\",\"class\":\"dnd-off\",\"alt\":\"off\"}"
    else
        echo "{\"text\":\"$DND_ON_ICON\",\"tooltip\":\"Do Not Disturb: ON\",\"class\":\"dnd-on\",\"alt\":\"on\"}"
    fi
}

# Function to toggle DND
toggle_dnd() {
    if is_dunst_paused; then
        unpause_dunst
    else
        pause_dunst
    fi
}

# Main script logic
case "${1:-toggle}" in
    "toggle")
        toggle_dnd
        ;;
    "on")
        pause_dunst
        ;;
    "off")
        unpause_dunst
        ;;
    "status")
        get_status
        ;;
    *)
        echo "Usage: $0 [toggle|status|on|off]"
        echo "  toggle  - Toggle do not disturb mode (default)"
        echo "  on      - Turn on do not disturb mode"
        echo "  off     - Turn off do not disturb mode"
        echo "  status  - Output JSON status for waybar"
        exit 1
        ;;
esac
