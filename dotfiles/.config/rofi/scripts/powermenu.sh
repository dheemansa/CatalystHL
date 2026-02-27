#!/usr/bin/env bash
set -euo pipefail

# Power menu options and corresponding icons
#options=("Lock" "Suspend" "Logout" "Reboot" "Shutdown" "Hibernate")
#icons=("" "" "󰿅" "󱄌" "" "󰒲")

options=("Lock" "Suspend" "Logout" "Reboot" "Shutdown")
icons=("" "" "󰍃" "󰑓" "" )
ROFI_THEME="$HOME/.config/rofi/themes/powermenu.rasi"

# Show Rofi menu
rofi_cmd() {
    local entries=()
    for i in "${!options[@]}"; do
        entries+=("${icons[$i]}")
    done

    printf "%s\n" "${entries[@]}" | rofi -dmenu -i -p "Power Menu" -theme "${ROFI_THEME}"
}

# Main
main() {
    selected=$(rofi_cmd)
    echo "Selected: $selected"
    case "$selected" in
        "") loginctl lock-session ;;
        "") systemctl suspend ;;
        "󰍃") hyprctl dispatch exit ;;  # adjust for your WM logout command
        "󰑓") systemctl reboot ;;
        "") systemctl poweroff ;;
        *) exit 1 ;;
    esac
}

main
