#!/bin/bash

# Get the absolute path to the source config directory
SOURCE_DIR="$(dirname "$(realpath "$0")")/../config"
DEST_DIR="$HOME/.config"

echo "Copying config files from: $SOURCE_DIR"
echo "To: $DEST_DIR"
echo

# Make sure ~/.config exists
mkdir -p "$DEST_DIR"

# Loop through each folder inside config/
for dir in "$SOURCE_DIR"/*; do
    if [ -d "$dir" ]; then
        folder_name="$(basename "$dir")"
        target_path="$DEST_DIR/$folder_name"

        # Delete existing folder if it exists
        if [ -d "$target_path" ]; then
            echo "Removing existing ~/.config/$folder_name"
            rm -rf "$target_path"
        fi

        # Copy new folder
        echo "Copying $folder_name → ~/.config/"
        cp -r "$dir" "$DEST_DIR/"
    fi
done

echo
echo "✅ All config folders copied to ~/.config (replaced if already present)."
