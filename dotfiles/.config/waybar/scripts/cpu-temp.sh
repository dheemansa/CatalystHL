#!/bin/bash

SENSORS_OUTPUT=$(sensors)

# Extract core temps (Intel-style output: "Core 0:", "Core 1:", etc.)
core_temps=$(echo "$SENSORS_OUTPUT" | grep -E '^Core [0-9]:' | awk '{print $3}' | sed 's/+//g; s/°C//g')

# Average core temps
avg_temp=$(echo "$core_temps" | awk '{sum+=$1} END {if (NR > 0) printf "%.1f", sum/NR; else print "N/A"}')

# Determine class for styling
if [[ "$avg_temp" == "N/A" ]]; then
    temp_class="unknown"
elif (( $(echo "$avg_temp < 60" | bc -l) )); then
    temp_class="cool"
elif (( $(echo "$avg_temp < 75" | bc -l) )); then
    temp_class="warm"
else
    temp_class="hot"
fi

# Tooltip with Core X + temp
core_info=$(echo "$SENSORS_OUTPUT" | grep -E '^Core [0-9]:' | awk '{printf "%s %s\n", $1, $3}')

# Escape tooltip safely (remove trailing \n)
tooltip_escaped=$(echo "$core_info" | awk '{gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); printf "%s\\n", $0}' | sed '$s/\\n$//')

# Output JSON for Waybar
printf '{"text":"%s°C","tooltip":"%s","class":"%s"}\n' "$avg_temp" "$tooltip_escaped" "$temp_class"
