#!/usr/bin/env bash

# ========== Screenshot Script ==========
# Uses grim and slurp to capture screenshots in Hyprland
# Modes: region, window, monitor

# --- Defaults ---
MODE="monitor"
COPY=false
FILENAME=""
SHOW_NOTIFICATION=true
# Use standard XDG pictures folder or fallback
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$SAVE_DIR"

# --- Dependency Check ---
check_deps() {
  for cmd in grim slurp wl-copy jq hyprctl notify-send; do
    if ! command -v "$cmd" &> /dev/null; then
      echo "Error: Required command '$cmd' is not installed." >&2
      notify-send "Screenshot Error" "Missing dependency: $cmd" -u critical
      exit 1
    fi
  done
}
check_deps

# --- Help Function ---
show_help() {
    cat <<EOF
Usage: screenshot.sh [options]

Options:
  -h                Show this help message
  -m [mode]         Screenshot mode: region, window, monitor
                      region  - Interactively select an area
                      window  - Interactively select a window
                      monitor - Capture monitor under cursor (default)
  -c                Copy screenshot to clipboard using wl-copy
  -f [filename]     Set custom filename (without .png extension)
  -s                Silent mode (no notification popup)
EOF
}

# --- Parse Arguments ---
while getopts ":hm:cf:s" opt; do
  case $opt in
    h) show_help; exit 0 ;;
    m) MODE=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]') ;;
    c) COPY=true ;;
    f) FILENAME="$OPTARG" ;;
    s) SHOW_NOTIFICATION=false ;;
    \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; exit 1 ;;
  esac
done

# --- File Path Setup ---
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
NAME="${FILENAME:-screenshot_$TIMESTAMP}"
FILE="$SAVE_DIR/$NAME.png"

# --- Geometry Selection ---
GEOM=""
case "$MODE" in
  region)
    # Let user freely select a region
    GEOM=$(slurp -b "#FFFFFF44")
    [ -z "$GEOM" ] && exit 1 # Cancelled
    ;;

  window)
    # Get the active workspace ID
    ACTIVE_ID=$(hyprctl activeworkspace -j | jq '.id')

    # Get visible windows on active workspace
    WINDOWS=$(hyprctl clients -j | jq -r --argjson active_id "$ACTIVE_ID" '.[] | select(.hidden == false and .workspace.id == $active_id) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.address)"')

    # Select window via slurp
    SELECTED_ADDRESS=$(echo "$WINDOWS" | slurp -r -b "#FFFFFF44" -f "%l")
    [ -z "$SELECTED_ADDRESS" ] && exit 1

    # Get exact geometry from address
    GEOM=$(hyprctl clients -j | jq -r --arg addr "$SELECTED_ADDRESS" '.[] | select(.address == $addr) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
    ;;

  monitor)
    # Get cursor position
    CURSOR_POS=$(hyprctl cursorpos -j)
    CX=$(echo "$CURSOR_POS" | jq '.x')
    CY=$(echo "$CURSOR_POS" | jq '.y')

    # Find monitor containing cursor
    GEOM=$(hyprctl monitors -j | jq -r --argjson cx "$CX" --argjson cy "$CY" '
      .[] | select(
        .x <= $cx and $cx < .x + .width and
        .y <= $cy and $cy < .y + .height
      ) | "\(.x),\(.y) \(.width)x\(.height)"
    ')

    # Fallback to active monitor
    if [ -z "$GEOM" ]; then
      MONITOR_NAME=$(hyprctl activeworkspace -j | jq -r '.monitor')
      GEOM=$(hyprctl monitors -j | jq -r ".[] | select(.name==\"$MONITOR_NAME\") | \"\(.x),\(.y) \(.width)x\(.height)\"")
    fi
    ;;

  *)
    echo "Invalid mode: $MODE" >&2
    exit 1
    ;;
esac

[ -z "$GEOM" ] && { echo "Geometry selection failed." >&2; exit 1; }

# --- Take Screenshot ---
grim -g "$GEOM" "$FILE" || { 
    notify-send "Screenshot Failed" "Could not capture image." -u critical
    exit 1 
}

# --- Clipboard Copy ---
if $COPY; then
  wl-copy < "$FILE"
fi

# --- Notification ---
if $SHOW_NOTIFICATION; then
  MODE_DISPLAY=$(echo "$MODE" | awk '{ print toupper(substr($0,1,1)) tolower(substr($0,2)) }')
  ACTION_TEXT="Saved"
  if $COPY; then ACTION_TEXT="Saved & Copied"; fi
  
  notify-send "Screenshot ($MODE_DISPLAY)" "$ACTION_TEXT: $(basename "$FILE")" -i "$FILE" -a Screenshot
fi
