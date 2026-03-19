#!/bin/bash
if pgrep -x "hyprsunset" > /dev/null; then
    pkill hyprsunset
    notify-send "Blue Filter" "Disabled" -a "Hyprsunset" -h "boolean:transient:true"
else
    hyprsunset > /dev/null 2>&1 &
    notify-send "Blue Filter" "Enabled" -a "Hyprsunset" -h "boolean:transient:true"
fi

