#!/bin/bash
set -euo pipefail

SIGNAL_ICONS=("󰤟" "󰤢" "󰤥" "󰤨")
SECURED_SIGNAL_ICONS=("󰤡" "󰤤" "󰤧" "󰤪")
WIFI_CONNECTED_ICON=""
CANCEL_ICON="󰗼"
REFRESH_ICON="󰑓"

# Check for required dependencies
for cmd in nmcli rofi notify-send; do
    command -v "$cmd" >/dev/null 2>&1 || { echo >&2 "Error: $cmd is required but not installed."; exit 1; }
done

# Define the theme arguments as an array
# This ensures that -theme-str and its value are passed as two distinct arguments to rofi

# Define the base directory for your Rofi themes
ROFI_THEME="$HOME/.config/rofi/themes/network-manager.rasi"
ROFI_THEME_ARGS=( -theme "${ROFI_THEME}" )

ROFI_THEME_INPUT="$HOME/.config/rofi/themes/network-manager-input.rasi"
ROFI_THEME_ARGS_INPUT=( -theme "${ROFI_THEME_INPUT}" )

WIFI_DEV=$(nmcli device status | awk '$2=="wifi"{print $1; exit}')
[ -z "$WIFI_DEV" ] && notify-send -a "Network Manager" "Wi-Fi" "No Wi-Fi device found" && exit 1

wifi_is_enabled() {
    [[ "$(nmcli radio wifi)" == "enabled" ]]
}

get_connected_ssid() {
    nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2 || true
}

get_ethernet_status() {
    local eth_device=$(nmcli device status | awk '$2=="ethernet" && $3=="connected" {print $1; exit}')
    if [[ -n "$eth_device" ]]; then
        echo "󰈀  Connected via Ethernet ($eth_device)"
    else
        echo "󰈀  Not Connected via Ethernet"
    fi
}

toggle_wifi() {
    if wifi_is_enabled; then
        nmcli radio wifi off && notify-send -a "Network Manager" "Wi-Fi" "Wi-Fi Disabled"
    else
        nmcli radio wifi on && notify-send -a "Network Manager" "Wi-Fi" "Wi-Fi Enabled"
    fi
}

disconnect_menu() {
    local ssid="$1"
    # Use "${ROFI_THEME_ARGS[@]}" to expand the array correctly
    local choice=$(printf "  Disconnect from $ssid\n$CANCEL_ICON  Cancel" | rofi -dmenu -p "Connected to $ssid:" "${ROFI_THEME_ARGS[@]}")

    case "$choice" in
        "  Disconnect from $ssid")
            nmcli device disconnect "$WIFI_DEV" && notify-send -a "Network Manager" "Wi-Fi" "Disconnected from $ssid"
            ;;
    esac
}

show_wifi_list() {
    local -a ssids=()
    local -a formatted_ssids=()
    local active_ssid=$(get_connected_ssid)

    while IFS=: read -r in_use signal security ssid; do
        [[ -z "$ssid" ]] && continue

        local level=$((signal / 25))
        (( level > 3 )) && level=3

        local icon="${SIGNAL_ICONS[$level]}"
        [[ "$security" == *WPA* || "$security" == *WEP* ]] && icon="${SECURED_SIGNAL_ICONS[$level]}"

        local display="$icon $ssid"
        [[ "$in_use" == "*" ]] && display="$WIFI_CONNECTED_ICON $display"

        ssids+=("$ssid")
        formatted_ssids+=("$display")
    done < <(nmcli --terse --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list)

    formatted_ssids=("$REFRESH_ICON  Refresh List" "${formatted_ssids[@]}" "$CANCEL_ICON  Cancel/Back")

    # Use "${ROFI_THEME_ARGS[@]}"
    selected=$(printf "%s\n" "${formatted_ssids[@]}" | rofi -dmenu -i -p "Select Network:" "${ROFI_THEME_ARGS[@]}")

    if [[ -z "$selected" || "$selected" == "$CANCEL_ICON  Cancel/Back" ]]; then
        return
    fi

    if [[ "$selected" == "$REFRESH_ICON  Refresh List" ]]; then
        notify-send -a "Network Manager" "Network Manager" "Scanning Wi-Fi"
        nmcli --terse --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list --rescan yes #to force rescan
        show_wifi_list  
        return
    fi

    ssid_index=-1
    for i in "${!formatted_ssids[@]}"; do
        [[ "${formatted_ssids[$i]}" == "$selected" ]] && ssid_index=$((i - 1)) && break
    done

    chosen_ssid="${ssids[$ssid_index]}"

    if [[ "$chosen_ssid" == "$active_ssid" ]]; then
        # Use "${ROFI_THEME_ARGS[@]}"
        action=$(printf "  Disconnect\n  Forget\n$CANCEL_ICON  Cancel" | rofi -dmenu -p "Action for $chosen_ssid:" "${ROFI_THEME_ARGS[@]}")
        case "$action" in
            "  Disconnect")
                nmcli device disconnect "$WIFI_DEV" && notify-send -a "Network Manager" "Wi-Fi" "Disconnected from $chosen_ssid"
                ;;
            "  Forget")
                nmcli connection delete id "$chosen_ssid" && notify-send -a "Network Manager" "Wi-Fi" "Forgotten: $chosen_ssid"
                ;;
        esac
    else
        saved=$(nmcli -t -f NAME,TYPE connection show | grep -Fx "$chosen_ssid:802-11-wireless" || true)
        if [[ "$saved" ]]; then
            action=$(printf "󰒢  Connect\n  Forget\n$CANCEL_ICON  Cancel" | rofi -dmenu -p "Action for $chosen_ssid:" "${ROFI_THEME_ARGS[@]}")
            case "$action" in
                "󰒢  Connect")
                    if nmcli connection up id "$chosen_ssid" ifname "$WIFI_DEV"; then
                        notify-send -a "Network Manager" "Wi-Fi" "Connected to $chosen_ssid"
                    else
                        notify-send -a "Network Manager" "Wi-Fi" "Failed to connect to $chosen_ssid"
                    fi
                    ;;
                "  Forget")
                    nmcli connection delete id "$chosen_ssid" && notify-send -a "Network Manager" "Wi-Fi" "Forgotten: $chosen_ssid"
                    ;;
            esac
        else
            # Use the input theme for the password prompt
            # To enable password censoring (displaying asterisks), uncomment the line below and comment the next line.
            # pass=$(rofi -dmenu -p "Password for $chosen_ssid:" -password "${ROFI_THEME_ARGS_INPUT[@]}")
            pass=$(rofi -dmenu -p "Password for $chosen_ssid:" "${ROFI_THEME_ARGS_INPUT[@]}")
            [[ -z "$pass" ]] && return
            if nmcli device wifi connect "$chosen_ssid" password "$pass" ifname "$WIFI_DEV"; then
                notify-send -a "Network Manager" "Wi-Fi" "Connected to $chosen_ssid"
            else
                notify-send -a "Network Manager" "Wi-Fi" "Failed to connect to $chosen_ssid. Check password or network."
            fi
        fi
    fi
}

main_menu() {
    while true; do
        local was_enabled=false
        if wifi_is_enabled; then
            toggle_option="󱚽  Wi-Fi Enabled (click to disable)"
            was_enabled=true
        else
            toggle_option="󱛅  Wi-Fi Disabled (click to enable)"
        fi

        local current_ssid=$(get_connected_ssid)
        local status_option="󰤨  Not Connected"
        [[ -n "$current_ssid" ]] && status_option="$WIFI_CONNECTED_ICON  Connected to $current_ssid"

        local eth_status=$(get_ethernet_status)

        # Begin menu
        local menu_items="$toggle_option\n"
        menu_items+="$eth_status\n"

        if $was_enabled; then
            menu_items+="$status_option\n"
            menu_items+="󰤧  Show Available Wi-Fi\n"
        fi

        menu_items+="$CANCEL_ICON  Exit Network Manager"

        # Use "${ROFI_THEME_ARGS[@]}"
        local choice=$(printf "$menu_items" | rofi -dmenu -p " Network Menu:" "${ROFI_THEME_ARGS[@]}")

        case "$choice" in
            "$toggle_option")
                toggle_wifi
                if $was_enabled; then
                    break  # Wi-Fi was just disabled
                fi
                ;;
            "$WIFI_CONNECTED_ICON  Connected to $current_ssid")
                disconnect_menu "$current_ssid"
                ;;
            "󰤧  Show Available Wi-Fi")
                show_wifi_list
                ;;
            "$CANCEL_ICON  Exit Network Manager" | "")
                break
                ;;
        esac
    done
}


main_menu
