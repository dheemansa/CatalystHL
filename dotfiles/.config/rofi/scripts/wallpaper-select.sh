#!/usr/bin/env bash
set -euo pipefail
# Debug mode enabled
# set -x

# Use env vars if set (e.g. from Hyprland), else default
WALLPAPER_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${WALLPAPER_CACHE:-$HOME/.cache/wallpaper_thumbnails}"

JSON_FILE="$HOME/.local/share/CatalystHL/wallpaper.json"
LINK_PATH="$HOME/.local/share/CatalystHL/current-wallpaper"
# rofi theme override (just imports your custom theme file)
ROFI_THEME_STR="$HOME/.config/rofi/themes/wallpaper-select.rasi"

mkdir -p "$(dirname "$LINK_PATH")"

# check deps
for cmd in jq rofi swww; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Error: $cmd not found." >&2; exit 1; }
done

# --- Step 1: Select Folder ---

folder_count=$(jq 'length' "$JSON_FILE")

if [[ "$folder_count" -eq 1 ]]; then
  selected_folder=$(jq -r 'keys[0]' "$JSON_FILE")
else

# Extract folders and their first image (as preview)
# Output format: "FolderName\tFirstImageRelPath"
mapfile -t folders < <(jq -r 'to_entries[] | "\(.key)\t\(.value[0])"' "$JSON_FILE")

# Generate the input string for Rofi
# We use a loop to print directly to the pipe instead of capturing in a variable
# capturing in a var ($(...)) strips null bytes in Bash!
gen_folder_menu() {
  for line in "${folders[@]}"; do
    folder_name="${line%%$'\t'*}"
    first_img="${line#*$'\t'}"
    thumb="$CACHE_DIR/$first_img"
    
    if [[ -f "$thumb" ]]; then
      # echo -en allows sending \0 (null) and \x1f (unit separator)
      echo -en "${folder_name}\0icon\x1f${thumb}\n"
    else
      echo -en "${folder_name}\n"
    fi
  done
}

# Debug: uncomment to see raw output
# gen_folder_menu | cat -v >&2

  selected_folder=$(gen_folder_menu | rofi -dmenu \
      -i \
      -p "Select Category:" \
      -no-custom \
      -show-icons \
      -theme "$ROFI_THEME_STR")
fi
[ -z "${selected_folder:-}" ] && exit 0

# --- Step 2: Select Wallpaper ---

# Load wallpapers for the selected folder
mapfile -t wallpapers < <(jq -r --arg folder "$selected_folder" '.[$folder][]' "$JSON_FILE")

gen_wallpaper_menu() {
  for rel in "${wallpapers[@]}"; do
    name=$(basename "$rel")
    thumb="$CACHE_DIR/$rel"
    
    if [[ -f "$thumb" ]]; then
      echo -en "${name}\0icon\x1f${thumb}\n"
    else
      echo -en "${name}\n"
    fi
  done
}

selected_file_name=$(gen_wallpaper_menu | rofi -dmenu \
    -i \
    -p "Select Wallpaper ($selected_folder):" \
    -no-custom \
    -show-icons \
    -theme "$ROFI_THEME_STR")


[ -z "${selected_file_name:-}" ] && exit 0

# Find full relative path for the selected filename (within the chosen folder)
# We know the folder, so we just need to reconstruct the path or find it in the list
chosen_rel=""
for rel in "${wallpapers[@]}"; do
  if [[ "$(basename "$rel")" == "$selected_file_name" ]]; then
    chosen_rel="$rel"
    break
  fi
done

if [[ -z "$chosen_rel" ]]; then
  echo "Error: Could not resolve file path." >&2
  exit 1
fi

# --- Apply Wallpaper ---
# swww img "$WALLPAPER_DIR/$chosen_rel" --transition-type wipe --transition-fps 60 --transition-step 60
lumi -i "$WALLPAPER_DIR/$chosen_rel"

# Update Symlink
rm -f "$LINK_PATH"
ln -s "$WALLPAPER_DIR/$chosen_rel" "$LINK_PATH"

echo "Wallpaper set to: $chosen_rel"
