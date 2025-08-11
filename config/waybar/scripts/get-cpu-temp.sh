#!/bin/bash

SENSORS_OUTPUT=$(sensors)

# Extract core temps
core_temps=$(echo "$SENSORS_OUTPUT" | grep -E '^Core [0-9]:' | awk '{print $3}' | sed 's/+//g; s/°C//g')

# Average core temps
avg_temp=$(echo "$core_temps" | awk '{sum+=$1} END {if (NR > 0) printf "%.1f", sum/NR; else print "N/A"}')

# Determine class for styling
if (( $(echo "$avg_temp < 60" | bc -l) )); then
    temp_class="cool"
elif (( $(echo "$avg_temp < 75" | bc -l) )); then
    temp_class="warm"
else
    temp_class="hot"
fi

# Tooltip with Core X + temp
core_info=$(echo "$SENSORS_OUTPUT" | grep -E '^Core [0-9]:' | awk '{printf "%s %s\n", $1, $3}')

# GPU temp (optional)
gpu_info=$(echo "$SENSORS_OUTPUT" | grep -i 'gpu' | grep -Eo '\+?[0-9.]+°C')
if [[ -n "$gpu_info" ]]; then
    tooltip="$core_info"$'\n'"GPU: $gpu_info"
else
    tooltip="$core_info"
fi

# Escape tooltip
tooltip_escaped=$(echo "$tooltip" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')

# Output JSON with class
printf '{"text":" %s°C","tooltip":"%s","class":"%s"}\n' "$avg_temp" "$tooltip_escaped" "$temp_class"
