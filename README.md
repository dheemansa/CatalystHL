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

## Key Dependencies

The `install.sh` script automates the installation of most packages, which are listed in the `packages.pkglist` file.

However, one crucial dependency for wallpaper management, **Luminol (`lumi`)**, is not available in the official
repositories or the AUR and must be installed manually.

- **For Luminol installation instructions, please visit the official repository:
  [dheemansa/Luminol](https://github.com/dheemansa/Luminol)**

## Usage

After the installation script is complete, you may need to log out and log back in for all changes to take full effect.

