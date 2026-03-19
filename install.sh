#!/bin/bash
# Minimal bootstrap script to ensure Python is installed.

set -e

# Change to the directory where the script is located
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo ":: Python 3 is required but not installed. Installing..."
    # Ensure system is Arch Linux based
    if [ -f /etc/arch-release ]; then
        sudo pacman -S --needed --noconfirm python
    else
        echo "This install script is designed for Arch Linux." >&2
        echo "Please install python3 manually for your system." >&2
        exit 1
    fi
fi

echo ":: Starting Python installer..."
# Hand over execution to the Python script
exec python3 install.py "$@"
