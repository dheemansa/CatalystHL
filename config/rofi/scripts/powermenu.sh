#!/usr/bin/env bash

# Get system info
uptime_info=$(uptime -p | sed -e 's/up //g')
host=$(hostnamectl hostname)

# Power menu options and corresponding icons
options=("Lock" "Suspend" "Logout" "Reboot" "Shutdown" "Hibernate")
icons=("" "" "󰿅" "󱄌" "" "󰒲")

# Theme file
ROFI_THEME="$HOME/.config/rofi/themes/powermenu.rasi"
ROFI_THEME_ARGS=(-theme-str "@import \"$ROFI_THEME\"")

# Show Rofi menu
rofi_cmd() {
    local entries=()
    for i in "${!options[@]}"; do
        entries+=("${icons[$i]} ${options[$i]}")
    done

    printf "%s\n" "${entries[@]}" | \
        rofi -dmenu -i \
            -p " $USER@$host" \
            -mesg " Uptime: $uptime_info" \
            "${ROFI_THEME_ARGS[@]}" | awk '{print $1}'
}

# Run selected action
run_cmd() {
    case "$1" in
        "") swaylock ;;
        "") systemctl suspend ;;
        "󰿅") hyprctl dispatch exit 0 ;;
        "󱄌") systemctl reboot ;;
        "") systemctl poweroff ;;
        "󰒲") systemctl hibernate ;;
        *) exit 1 ;;
    esac
}

# Main
selected=$(rofi_cmd)
[ -n "$selected" ] && run_cmd "$selected"
