#!/bin/bash
set -e

# Default colors
ENABLED_COLOR="#A3BE8C"
DISABLED_COLOR="#D35F5E"
SESSION_TYPE="$XDG_SESSION_TYPE"

# Icons
SIGNAL_ICONS=("󰤟" "󰤢" "󰤥" "󰤨")
SECURED_SIGNAL_ICONS=("󰤡" "󰤤" "󰤧" "󰤪")
WIFI_CONNECTED_ICON=""
ETHERNET_CONNECTED_ICON="󰈀"
DISCONNECTED_ICON=""

# Parse CLI args
while [[ $# -gt 0 ]]; do
    case $1 in
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

# Output network status
get_status() {
    local status_icon="$DISCONNECTED_ICON"
    local status_color="$DISABLED_COLOR"

    if nmcli -t -f TYPE,STATE device status | grep -q 'ethernet:connected'; then
        status_icon="$ETHERNET_CONNECTED_ICON"
        status_color="$ENABLED_COLOR"
    elif nmcli -t -f TYPE,STATE device status | grep -q 'wifi:connected'; then
        local wifi_info
        wifi_info=$(nmcli --terse --fields "IN-USE,SIGNAL,SECURITY,SSID" device wifi list --rescan no | grep '\*')
        if [ -n "$wifi_info" ]; then
            IFS=: read -r _ signal security _ <<< "$wifi_info"
            local level=$((signal / 25))
            [[ $level -gt 3 ]] && level=3

            if [[ "$security" == *WPA* || "$security" == *WEP* ]]; then
                status_icon="${SECURED_SIGNAL_ICONS[$level]}"
            else
                status_icon="${SIGNAL_ICONS[$level]}"
            fi

            status_color="$ENABLED_COLOR"
        fi
    fi

    if [[ "$SESSION_TYPE" == "wayland" ]]; then
        echo "<span color=\"$status_color\">$status_icon</span>"
    else
        echo "%{F$status_color}$status_icon%{F-}"
    fi
}

get_status
