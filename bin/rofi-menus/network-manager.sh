#!/bin/bash

SESSION_TYPE="$XDG_SESSION_TYPE"
ENABLED_COLOR="#A3BE8C"
DISABLED_COLOR="#D35F5E"
SIGNAL_ICONS=("󰤟" "󰤢" "󰤥" "󰤨")
SECURED_SIGNAL_ICONS=("󰤡" "󰤤" "󰤧" "󰤪")
WIFI_CONNECTED_ICON=""
ETHERNET_CONNECTED_ICON=""

get_status() {
    local status_icon=""
    local status_color=$DISABLED_COLOR

    if nmcli -t -f TYPE,STATE device status | grep 'ethernet:connected' > /dev/null; then
        status_icon="󰈀"
        status_color=$ENABLED_COLOR
    elif nmcli -t -f TYPE,STATE device status | grep 'wifi:connected' > /dev/null; then
        local wifi_info
        wifi_info=$(nmcli --terse --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list --rescan no | grep '\*')
        if [ -n "$wifi_info" ]; then
            IFS=: read -r in_use signal security ssid <<< "$wifi_info"
            local signal_level=$((signal / 25))
            if (( signal_level > 3 )); then
                signal_level=3
            fi
            local signal_icon="${SIGNAL_ICONS[$signal_level]}"
            if [[ "$security" == *WPA* || "$security" == *WEP* ]]; then
                signal_icon="${SECURED_SIGNAL_ICONS[$signal_level]}"
            fi
            status_icon="$signal_icon"
            status_color=$ENABLED_COLOR
        else
            status_icon=""
            status_color=$DISABLED_COLOR
        fi
    fi

    if [[ "$SESSION_TYPE" == "wayland" ]]; then
        echo "<span color=\"$status_color\">$status_icon</span>"
    elif [[ "$SESSION_TYPE" == "x11" ]]; then
        echo "%{F$status_color}$status_icon%{F-}"
    fi
}

manage_wifi() {
    nmcli --terse --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list > /tmp/wifi_list.txt

    local ssids=()
    local formatted_ssids=()
    local active_ssid=""

    while IFS=: read -r in_use signal security ssid; do
        if [ -z "$ssid" ]; then continue; fi

        local signal_level=$((signal / 25))
        if (( signal_level > 3 )); then
            signal_level=3
        fi
        local signal_icon="${SIGNAL_ICONS[$signal_level]}"
        if [[ "$security" == *WPA* || "$security" == *WEP* ]]; then
            signal_icon="${SECURED_SIGNAL_ICONS[$signal_level]}"
        fi

        local formatted="$signal_icon $ssid"
        if [[ "$in_use" =~ \* ]]; then
            active_ssid="$ssid"
            formatted="$WIFI_CONNECTED_ICON $formatted"
        fi
        ssids+=("$ssid")
        formatted_ssids+=("$formatted")
    done < /tmp/wifi_list.txt

    # Add a single Cancel/Exit button at the bottom
    formatted_ssids+=("󰗼  Cancel/Exit")

    local formatted_list=""
    for formatted_ssid in "${formatted_ssids[@]}"; do
        formatted_list+="$formatted_ssid\n"
    done

    formatted_list=$(printf "%s" "$formatted_list")

    local chosen_network=$(echo -e "$formatted_list" | rofi -dmenu -i -selected-row 1 -p "Wi-Fi SSID: " -me-select-entry '' -me-accept-entry MousePrimary)

    if [[ "$chosen_network" == "󰗼  Cancel/Exit" || -z "$chosen_network" ]]; then
        rm /tmp/wifi_list.txt
        return
    fi

    local ssid_index=-1
    for i in "${!formatted_ssids[@]}"; do
        if [[ "${formatted_ssids[$i]}" == "$chosen_network" ]]; then
            ssid_index=$i
            break
        fi
    done

    local chosen_id="${ssids[$ssid_index]}"

    # Get the Wi-Fi device name dynamically
    local WIFI_DEV
    WIFI_DEV=$(nmcli device status | awk '$2=="wifi"{print $1; exit}')

    local action
    if [[ "$chosen_id" == "$active_ssid" ]]; then
        action="  Disconnect"
    else
        action="󰸋  Connect"
    fi

    action=$(echo -e "$action\n  Forget\n󰗼  Cancel/Exit" | rofi -dmenu -p "Action: " -me-select-entry '' -me-accept-entry MousePrimary)
    case $action in
        "󰸋  Connect")
            local success_message="You are now connected to the Wi-Fi network \"$chosen_id\"."
            local saved_connections=$(nmcli -g NAME connection show)
            if [[ $(echo "$saved_connections" | grep -Fx "$chosen_id") ]]; then
                nmcli connection up id "$chosen_id" | grep "successfully" && notify-send "Connection Established" "$success_message"
            else
                local wifi_password=$(rofi -dmenu -p "Password: " -password -me-select-entry '' -me-accept-entry MousePrimary)
                nmcli device wifi connect "$chosen_id" password "$wifi_password" | grep "successfully" && notify-send "Connection Established" "$success_message"
            fi
            ;;
        "  Disconnect")
            nmcli device disconnect "$WIFI_DEV" && notify-send "Disconnected" "You have been disconnected from $chosen_id."
            ;;
        "  Forget")
            nmcli connection delete id "$chosen_id" && notify-send "Forgotten" "The network $chosen_id has been forgotten."
            ;;
        "󰗼  Cancel/Exit" | "")
            # Do nothing, just exit the action menu
            ;;
    esac

    rm /tmp/wifi_list.txt
}

manage_ethernet() {
    local eth_devices=$(nmcli device status | grep ethernet | awk '{print $1}')
    if [ -z "$eth_devices" ]; then
        notify-send "Error" "Ethernet device not found."
        return
    fi

    local eth_list=""
    for dev in $eth_devices; do
        local dev_status=$(nmcli device status | grep "$dev" | awk '{print $3}')
        if [ "$dev_status" = "connected" ]; then
            eth_list+="$ETHERNET_CONNECTED_ICON$dev\n"
        else
            eth_list+="$dev\n"
        fi
    done

    # Add a single Cancel/Exit button at the bottom
    eth_list="${eth_list}󰗼  Cancel/Exit\n"

    local chosen_device=$(echo -e "$eth_list" | rofi -dmenu -i -p "Select Ethernet device: " -me-select-entry '' -me-accept-entry MousePrimary)

    if [[ "$chosen_device" == "󰗼  Cancel/Exit" || -z "$chosen_device" ]]; then
        return
    fi

    chosen_device=$(echo $chosen_device | sed "s/$ETHERNET_CONNECTED_ICON//")
    local device_status=$(nmcli device status | grep "$chosen_device" | awk '{print $3}')

    if [ "$device_status" = "connected" ]; then
        nmcli device disconnect "$chosen_device" && notify-send "Disconnected" "You have been disconnected from $chosen_device."
    elif [ "$device_status" = "disconnected" ]; then
        nmcli device connect "$chosen_device" && notify-send "Connected" "You are now connected to $chosen_device."
    else
        notify-send "Error" "Unable to determine the action for $chosen_device."
    fi
}

main_menu() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --status)
                status_mode=true
                shift
                ;;
            --enabled-color)
                ENABLED_COLOR="$2"
                shift 2
                ;;
            --disabled-color)
                DISABLED_COLOR="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ $status_mode == true ]]; then
        get_status
        exit 0
    fi

    if ! pgrep -x "NetworkManager" > /dev/null; then
        echo -n "Root Password: "
        read -s password
        echo "$password" | sudo -S systemctl start NetworkManager
    fi

    local wifi_status=$(nmcli -fields WIFI g)
    local wifi_toggle
    if [[ "$wifi_status" =~ "enabled" ]]; then
        wifi_toggle="󱛅  Disable Wi-Fi"
        wifi_toggle_command="off"
        manage_wifi_btn="\n󱓥 Manage Wi-Fi"
    else
        wifi_toggle="󱚽  Enable Wi-Fi"
        wifi_toggle_command="on"
        manage_wifi_btn=""
    fi

    # Add Exit button at the top
    local menu_options="$wifi_toggle$manage_wifi_btn\n󱓥 Manage Ethernet\n󰗼  Exit"
    local chosen_option=$(echo -e "$menu_options" | rofi -dmenu -p " Network Management: " -me-select-entry '' -me-accept-entry MousePrimary)
    case $chosen_option in
        "󰗼  Exit")
            exit 0
            ;;
        "$wifi_toggle")
            nmcli radio wifi $wifi_toggle_command
            ;;
        "󱓥 Manage Wi-Fi")
            manage_wifi
            ;;
        "󱓥 Manage Ethernet")
            manage_ethernet
            ;;
    esac
}

main_menu "$@"
