#!/bin/bash

SIGNAL_ICONS=("󰤟" "󰤢" "󰤥" "󰤨")
SECURED_SIGNAL_ICONS=("󰤡" "󰤤" "󰤧" "󰤪")
WIFI_CONNECTED_ICON=""
CANCEL_ICON="󰗼"
REFRESH_ICON="󰑓"

# Define the theme arguments as an array
# This ensures that -theme-str and its value are passed as two distinct arguments to rofi


# Define the base directory for your Rofi themes
ROFI_THEME="~/.config/rofi/themes/network-manager.rasi"
ROFI_THEME_ARGS=( -theme-str "@import \"${ROFI_THEME}\"" )

ROFI_THEME_INPUT="~/.config/rofi/themes/network-manager-input.rasi"
ROFI_THEME_ARGS_INPUT=( -theme-str "@import \"${ROFI_THEME_INPUT}\"" )




WIFI_DEV=$(nmcli device status | awk '$2=="wifi"{print $1; exit}')
[ -z "$WIFI_DEV" ] && notify-send "Wi-Fi" "No Wi-Fi device found" && exit 1

wifi_is_enabled() {
    [[ "$(nmcli radio wifi)" == "enabled" ]]
}

get_connected_ssid() {
    nmcli -t -f ACTIVE,SSID dev wifi | grep '^yes' | cut -d: -f2
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
        nmcli radio wifi off && notify-send "Wi-Fi" "Wi-Fi Disabled"
    else
        nmcli radio wifi on && notify-send "Wi-Fi" "Wi-Fi Enabled"
    fi
}

disconnect_menu() {
    local ssid="$1"
    # Use "${ROFI_THEME_ARGS[@]}" to expand the array correctly
    local choice=$(printf "  Disconnect from $ssid\n$CANCEL_ICON  Cancel" | rofi -dmenu -p "Connected to $ssid:" "${ROFI_THEME_ARGS[@]}")

    case "$choice" in
        "  Disconnect from $ssid")
            nmcli device disconnect "$WIFI_DEV" && notify-send "Wi-Fi" "Disconnected from $ssid"
            ;;
    esac
}

show_wifi_list() {
    nmcli --terse --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list > /tmp/wifi_list.txt

    declare -a ssids formatted_ssids
    active_ssid=$(get_connected_ssid)

    while IFS=: read -r in_use signal security ssid; do
        [[ -z "$ssid" ]] && continue

        level=$((signal / 25))
        (( level > 3 )) && level=3

        icon="${SIGNAL_ICONS[$level]}"
        [[ "$security" == *WPA* || "$security" == *WEP* ]] && icon="${SECURED_SIGNAL_ICONS[$level]}"

        display="$icon $ssid"
        [[ "$in_use" == "*" ]] && display="$WIFI_CONNECTED_ICON $display"

        ssids+=("$ssid")
        formatted_ssids+=("$display")
    done < /tmp/wifi_list.txt

    formatted_ssids=("$REFRESH_ICON  Refresh List" "${formatted_ssids[@]}" "$CANCEL_ICON  Cancel/Back")

    # Use "${ROFI_THEME_ARGS[@]}"
    selected=$(printf "%s\n" "${formatted_ssids[@]}" | rofi -dmenu -i -p "Select Network:" "${ROFI_THEME_ARGS[@]}")

    if [[ -z "$selected" || "$selected" == "$CANCEL_ICON  Cancel/Back" ]]; then
        rm /tmp/wifi_list.txt
        return
    fi

    if [[ "$selected" == "$REFRESH_ICON  Refresh List" ]]; then
        rm /tmp/wifi_list.txt
        show_wifi_list  # recursive refresh
        return
    fi

    ssid_index=-1
    for i in "${!formatted_ssids[@]}"; do
        [[ "${formatted_ssids[$i]}" == "$selected" ]] && ssid_index=$((i - 1)) && break
    done

    chosen_ssid="${ssids[$ssid_index]}"

    if [[ "$chosen_ssid" == "$active_ssid" ]]; then
        # Use "${ROFI_THEME_ARGS[@]}"
        action=$(printf "  Disconnect\n  Forget\n$CANCEL_ICON  Cancel" | rofi -dmenu -p "Action for $chosen_ssid:" "${ROFI_THEME_ARGS[@]}")
        case "$action" in
            "  Disconnect")
                nmcli device disconnect "$WIFI_DEV" && notify-send "Wi-Fi" "Disconnected from $chosen_ssid"
                ;;
            "  Forget")
                nmcli connection delete id "$chosen_ssid" && notify-send "Wi-Fi" "Forgotten: $chosen_ssid"
                ;;
        esac
    else
        saved=$(nmcli -g NAME connection show | grep -Fx "$chosen_ssid")
        if [[ "$saved" ]]; then
            nmcli connection up id "$chosen_ssid" && notify-send "Wi-Fi" "Connected to $chosen_ssid"
        else
            # Use the input theme for the password prompt
            # To enable password censoring (displaying asterisks), uncomment the line below and comment the next line.
            # pass=$(rofi -dmenu -p "Password for $chosen_ssid:" -password "${ROFI_THEME_ARGS_INPUT[@]}")
            pass=$(rofi -dmenu -p "Password for $chosen_ssid:" "${ROFI_THEME_ARGS_INPUT[@]}")
            [[ -z "$pass" ]] && rm /tmp/wifi_list.txt && return
            nmcli device wifi connect "$chosen_ssid" password "$pass" && notify-send "Wi-Fi" "Connected to $chosen_ssid"
        fi
    fi

    rm /tmp/wifi_list.txt
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
