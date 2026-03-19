#!/bin/bash

INHIBIT_CMD="systemd-inhibit --what=idle sleep infinity"

if pgrep -f "$INHIBIT_CMD" > /dev/null; then
    # Caffeine is currently ON, so turn it OFF
    pkill -f "$INHIBIT_CMD"
    notify-send "Caffeine Mode" "Disabled" -a "Caffeine" -i caffeine-cup-empty -h "boolean:transient:true"
else
    # Caffeine is currently OFF, so turn it ON
    $INHIBIT_CMD > /dev/null 2>&1 &
    notify-send "Caffeine Mode" "Enabled" -a "Caffeine" -i caffeine-cup-full -h "boolean:transient:true"
fi
