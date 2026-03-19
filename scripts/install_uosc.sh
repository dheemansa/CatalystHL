#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo ":: Installing UOSC for MPV..."

MPV_DIR="$HOME/.config/mpv"
UOSC_ZIP="/tmp/uosc.zip"
UOSC_URL="https://github.com/tomasklaen/uosc/releases/latest/download/uosc.zip"

# Guarantee directory exists
mkdir -p "$MPV_DIR"

echo "Downloading UOSC..."
curl -fL --progress-bar "$UOSC_URL" -o "$UOSC_ZIP"

echo "Extracting UOSC..."
unzip -qo "$UOSC_ZIP" -d "$MPV_DIR"

# Clean up
rm -f "$UOSC_ZIP"

echo "-> UOSC installation complete."
