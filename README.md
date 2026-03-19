# CatalystHL - Hyprland Dotfiles

This repository contains my personal dotfiles and setup scripts for a Hyprland environment on Arch Linux.

## Installation

This setup is managed by an installation script. To install, clone this repository and run the `install.sh` script from
within the directory:

```sh
git clone https://github.com/dheemansa/CatalystHL.git
cd CatalystHL
./install.sh
```

The script will guide you through installing all necessary packages and will use GNU Stow to symlink the configuration
files into place.

> [!CAUTION]
> This setup uses **GNU Stow** to manage dotfiles via symbolic links.
> - **DO NOT** delete this repository after installation.
> - **DO NOT** clone this repository into `/tmp` or any other temporary directory, as the symlinks will break if the source files are removed.
> - It is recommended to keep this repository in a permanent location like `~/repos/` or `~/`.

## Key Dependencies

The `install.sh` script automates the installation of most packages, which are listed in the `packages.pkglist` file.

### Manual Installation Required

- **Luminol (`lumi`)**: Crucial for wallpaper management, but not in official repos or AUR. Visit [dheemansa/Luminol](https://github.com/dheemansa/Luminol).
- **Hardware Drivers**: You must manually install the appropriate drivers for your hardware (e.g., NVIDIA, Intel, AMD, etc.) before or after running the script.

## Usage

After the installation script is complete, you may need to log out and log back in for all changes to take full effect.

