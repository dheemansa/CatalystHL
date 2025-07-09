#!/bin/bash

# Auto-elevate if not root
if [ "$EUID" -ne 0 ]; then
  echo "Elevating to root using sudo..."
  exec sudo bash "$0" "$@"
fi

echo "You are running as root now."
# Continue with your install logic...
echo
echo "=== Graphics Driver Installer for Arch Linux ==="
echo

# --- Enable Multilib Repository ---
read -p "Enable the multilib repository? (Required for Steam, 32-bit drivers) [Y/n]: " multilib_choice
if [[ -z "$multilib_choice" || "$multilib_choice" =~ ^[yY]$ ]]; then
    echo "Enabling multilib..."
    sed -i "/^\[multilib\]/,/^Include/"'s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm
else
    echo "Multilib repository not enabled."
fi

# --- Prompt for GPU Driver Installation ---
echo
echo "Select your graphics card vendor to install drivers:"
options=("NVIDIA" "AMD" "Intel" "Skip")
select opt in "${options[@]}"; do
    case $opt in
        "NVIDIA")
            echo "Installing NVIDIA drivers..."
            pacman -S --noconfirm --needed \
                nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings libxnvctrl
            break
            ;;
        "AMD")
            echo "Installing AMD drivers..."
            pacman -S --noconfirm --needed \
                mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
            break
            ;;
        "Intel")
            echo "Installing Intel drivers..."
            pacman -S --noconfirm --needed \
                mesa lib32-mesa vulkan-intel lib32-vulkan-intel \
                intel-media-driver xf86-video-intel
            break
            ;;
        "Skip")
            echo "Skipping driver installation."
            break
            ;;
        *)
            echo "Invalid option. Please select a number from the list."
            ;;
    esac
done

echo
echo "Driver installation completed successfully."
exit 0

