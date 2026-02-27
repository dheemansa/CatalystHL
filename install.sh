#!/bin/bash
#
# install.sh
#
# This script automates the setup of the CatalystHL dotfiles on an
# Arch Linux-based system.
#
# It performs the following steps:
# 1. Verifies the system is running Arch Linux.
# 2. Checks for an AUR helper (paru or yay). If none is found, it
#    prompts the user to install one.
# 3. Installs all packages listed in 'packages.pkglist' using the helper.
# 4. Runs the Makefile to deploy the dotfiles using stow.

set -e

# Ensure the script is run from the directory it is located in
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# --- System Check ---
if [ ! -f /etc/arch-release ]; then
    echo "This install script is designed for Arch Linux." >&2
    echo "Please install dependencies manually for your system." >&2
    exit 1
fi

# --- Helper Functions ---
# Function to check for command existence
command_exists() {
    command -v "$1" &> /dev/null
}

# --- AUR Helper Logic ---
AUR_HELPER=""

if command_exists paru; then
    echo ":: Found 'paru'. Using it as the AUR helper."
    AUR_HELPER="paru"
elif command_exists yay; then
    echo ":: Found 'yay'. Using it as the AUR helper."
    AUR_HELPER="yay"
fi

# If no AUR helper is found, prompt the user to install one
if [ -z "$AUR_HELPER" ]; then
    echo ":: No AUR helper found (paru or yay)."
    read -p "Which AUR helper would you like to install? (paru/yay/none): " choice

    case "$choice" in
        paru|yay)
            echo ":: Installing '$choice'..."
            # git and base-devel are required to build an AUR helper.
            sudo pacman -S --needed --noconfirm git base-devel

            # Create a temporary directory for the build
            temp_dir=$(mktemp -d)
            trap 'rm -rf -- "$temp_dir"' EXIT

            git clone "https://aur.archlinux.org/$choice.git" "$temp_dir"
            (cd "$temp_dir" && makepkg -si --noconfirm)

            AUR_HELPER="$choice"
            echo "-> '$choice' has been installed successfully."
            ;;
        *)
            echo ":: Skipping AUR helper installation. Some packages may not be installed."
            ;;
    esac
fi

# --- Package Installation ---
if [ -n "$AUR_HELPER" ]; then
    echo ":: Installing all packages from packages.pkglist..."
    # Filter out comments/empty lines and install from the list
    grep -vE '^#|^$' packages.pkglist | xargs $AUR_HELPER -S --needed --noconfirm
    echo "-> Package installation complete."
else
    echo "Warning: Could not install packages because no AUR helper was found or selected." >&2
    echo "Please install the packages listed in 'packages.pkglist' manually." >&2
fi


# --- Run Makefile ---
echo ":: All dependencies satisfied. Running Makefile to deploy dotfiles..."
make

# Run the upwall script if it exists and is executable
if [ -x "$HOME/.local/bin/upwall" ]; then
    echo ":: Running upwall script to initialize wallpapers..."
    "$HOME/.local/bin/upwall"
else
    echo "Warning: upwall script not found or not executable at $HOME/.local/bin/upwall." >&2
    echo "Wallpaper thumbnails and configuration may not be set up correctly." >&2
fi


echo "-------------------------------------"
echo "Installation complete!"
echo "It's recommended to restart your terminal or log out and log back in."
echo "-------------------------------------"

exit 0
