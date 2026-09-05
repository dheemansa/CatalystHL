#!/usr/bin/env bash

export LC_ALL=C.UTF-8
SENSORS_OUTPUT=$(sensors 2>/dev/null || true)

# Helper: extract the first numeric temperature (e.g. +42.0°C) from a line and return numeric value without unit
extract_temp() {
  local line="$1"
  # awk: look for token matching [+|-]digits[.digits]°C, remove + and °C and print
  echo "$line" | awk '{
    if (match($0, /[+-]?[0-9]+(\.[0-9]+)?°C/)) {
      val = substr($0, RSTART, RLENGTH)
      gsub(/[+°C]/, "", val)
      print val
      exit
    }
  }'
}

# Try to find the most accurate CPU temperature reading using different fallbacks
temp=""
if temp_val=$(echo "$SENSORS_OUTPUT" | grep -E -m 1 'Package id [0-9]+:|Tdie:' ); then
    temp=$(extract_temp "$temp_val")
elif temp_val=$(echo "$SENSORS_OUTPUT" | grep -m 1 'Tctl:' ); then
    temp=$(extract_temp "$temp_val")
elif temp_val=$(echo "$SENSORS_OUTPUT" | grep -m 1 'Core 0:' ); then
    temp=$(extract_temp "$temp_val")
else
    temp=""
fi

# Determine class for styling
if [ -z "$temp" ]; then
    temp_class="unknown"
    avg_temp="N/A"
else
    # Ensure temp is a valid number before formatting/comparing
    if ! printf '%f' "$temp" >/dev/null 2>&1; then
        temp_class="unknown"
        avg_temp="N/A"
    else
        avg_temp=$(printf "%.1f" "$temp")
        # numeric comparisons using awk to avoid bc/(( )) oddities
        if awk "BEGIN { exit !($temp < 60) }"; then
            temp_class="cool"
        elif awk "BEGIN { exit !($temp < 75) }"; then
            temp_class="warm"
        else
            temp_class="hot"
        fi
    fi
fi

# Gather a tooltip showing all relevant core/package temperatures
tooltip_info=$(echo "$SENSORS_OUTPUT" | grep -E 'Package id [0-9]+:|Tdie:|Tctl:|Core [0-9]+:' || true)
# Normalize spaces and remove parenthetical highs/crit info for readability
tooltip_info=$(echo "$tooltip_info" | awk '{$1=$1; print}' | sed -E 's/ *\(.+$//')

# JSON-escape the tooltip safely. Prefer jq or python if available.
if [ -z "$tooltip_info" ]; then
    tooltip_escaped="No detailed sensors found"
else
    if command -v jq >/dev/null 2>&1; then
        # jq -Rs will read raw and produce a JSON string
        tooltip_escaped=$(printf '%s' "$tooltip_info" | jq -Rs .)
        # jq produced quoted string; remove surrounding quotes for embedding below
        tooltip_escaped=${tooltip_escaped#\"}
        tooltip_escaped=${tooltip_escaped%\"}
    elif command -v python3 >/dev/null 2>&1; then
        tooltip_escaped=$(printf '%s' "$tooltip_info" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read().rstrip()))')
        tooltip_escaped=${tooltip_escaped#\"}
        tooltip_escaped=${tooltip_escaped%\"}
    else
        # Fallback: simple escaping of backslash and double-quote, and convert newlines to \n
        tooltip_escaped=$(printf '%s' "$tooltip_info" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g')
    fi
fi

# Output JSON for Waybar. Don't append °C if avg_temp is "N/A"
if [ "$avg_temp" = "N/A" ]; then
  printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$avg_temp" "$tooltip_escaped" "$temp_class"
else
  printf '{"text":"%s°C","tooltip":"%s","class":"%s"}\n' "$avg_temp" "$tooltip_escaped" "$temp_class"
fi
