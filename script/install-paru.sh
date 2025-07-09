#!/bin/bash

# Auto-elevate if not root
if [ "$EUID" -ne 0 ]; then
    echo "Elevating to root using sudo..."
    exec sudo bash "$0" "$@"
fi

# Determine the user to build paru as
if [ -n "$SUDO_USER" ]; then
    normal_user="$SUDO_USER"
else
    echo "Error: Could not determine the non-root user to build paru as." >&2
    exit 1
fi

echo "Installing dependencies: git, base-devel..."
pacman -S --noconfirm --needed git base-devel

# Clone and build paru as the normal user
echo "Cloning and building paru AUR helper as user: $normal_user"
sudo -u "$normal_user" bash -c '
    cd /tmp
    if [ -d paru ]; then
        echo "Removing existing paru directory..."
        rm -rf paru
    fi
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
'

echo "✅ Paru installed successfully!"
exit 0
