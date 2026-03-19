#!/bin/bash
if pgrep -x "hypridle" > /dev/null; then
    killall hypridle
    notify-send "Caffeine Mode" "Enabled" -a "Caffeine"
else
    hypridle &
    notify-send "Caffeine Mode" "Disabled" -a "Caffeine"
fi

