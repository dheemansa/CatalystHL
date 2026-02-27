#!/bin/bash

export LC_ALL=C.UTF-8
SENSORS_OUTPUT=$(sensors 2>/dev/null)

# Try to find the most accurate CPU temperature reading using different fallbacks
# 1. Package id (Intel) or Tdie (AMD - actual die temp)
# 2. Tctl (AMD - control temp)
# 3. Core 0 (Fallback for older processors)
if temp_val=$(echo "$SENSORS_OUTPUT" | grep -E -m 1 'Package id [0-9]+:|Tdie:'); then
    temp=$(echo "$temp_val" | awk '{print $NF}' | tr -d '+°C')
elif temp_val=$(echo "$SENSORS_OUTPUT" | grep -m 1 'Tctl:'); then
    temp=$(echo "$temp_val" | awk '{print $2}' | tr -d '+°C')
elif temp_val=$(echo "$SENSORS_OUTPUT" | grep -m 1 'Core 0:'); then
    temp=$(echo "$temp_val" | awk '{print $3}' | tr -d '+°C')
else
    temp="N/A"
fi

# Determine class for styling
if [[ "$temp" == "N/A" ]]; then
    temp_class="unknown"
    avg_temp="N/A"
else
    # Round to 1 decimal place for Waybar output
    avg_temp=$(printf "%.1f" "$temp")
    
    if (( $(echo "$temp < 60" | bc -l) )); then
        temp_class="cool"
    elif (( $(echo "$temp < 75" | bc -l) )); then
        temp_class="warm"
    else
        temp_class="hot"
    fi
fi

# Gather a tooltip showing all relevant core/package temperatures
tooltip_info=$(echo "$SENSORS_OUTPUT" | grep -E 'Package id [0-9]+:|Tdie:|Tctl:|Core [0-9]+:' | awk '{$1=$1; print $0}' | sed 's/:\s*+/ /g' | sed 's/ (.*//')

# Escape tooltip safely (remove trailing \n)
if [ -z "$tooltip_info" ]; then
    tooltip_escaped="No detailed sensors found"
else
    tooltip_escaped=$(echo "$tooltip_info" | awk '{gsub(/\\/,"\\\\"); gsub(/"/,"\\\""); printf "%s\\n", $0}' | sed '$s/\\n$//')
fi

# Output JSON for Waybar
printf '{"text":"%s°C","tooltip":"%s","class":"%s"}\n' "$avg_temp" "$tooltip_escaped" "$temp_class"
