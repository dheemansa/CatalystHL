#!/bin/bash

# Resolve source and destination paths
SOURCE_DIR="$(dirname "$(realpath "$0")")/../bin"
DEST_DIR="$HOME/bin"

echo "Copying files from: $SOURCE_DIR"
echo "To: $DEST_DIR"

# Create ~/bin if it doesn't exist
mkdir -p "$DEST_DIR"

# Copy and overwrite existing files
cp -rf "$SOURCE_DIR/"* "$DEST_DIR/"

echo "✅ All files from 'bin' copied to ~/bin/ (overwritten if existed)."
