#!/bin/bash
# Usage: ./dnd.sh [toggle|status|on|off]

DND_ON_ICON="󱅫"
DND_OFF_ICON="󱏧"

# Function to check if dunst is paused
is_notification_paused() {
    swaync-client --get-dnd | grep -q "true"
}

# Function to pause dunst
pause_notification() {
    #notify-send -u low "Do Not Disturb" "Notifications paused" 2>/dev/null || true
    #sleep 5
    swaync-client --dnd-on
    
}

# Function to unpause dunst
unpause_notification() {
    swaync-client --dnd-off
    notify-send -u low "Do Not Disturb" "Notifications resumed" 2>/dev/null || true
}

# Function to get status for waybar
get_status() {
    if is_notification_paused; then
        echo "{\"text\":\"$DND_OFF_ICON\",\"tooltip\":\"Do Not Disturb: OFF\",\"class\":\"dnd-off\",\"alt\":\"off\"}"
    else
        echo "{\"text\":\"$DND_ON_ICON\",\"tooltip\":\"Do Not Disturb: ON\",\"class\":\"dnd-on\",\"alt\":\"on\"}"
    fi
}

# Function to toggle DND
toggle_dnd() {
    if is_notification_paused; then
        unpause_notification
    else
        pause_notification
    fi
}

# Main script logic
case "${1:-toggle}" in
    "toggle")
        toggle_dnd
        ;;
    "on")
        pause_notification
        ;;
    "off")
        unpause_notification
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
