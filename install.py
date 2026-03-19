#!/usr/bin/env python3

import os
import sys
import subprocess
import shutil
import tempfile
import argparse
from pathlib import Path
from datetime import datetime


# --- Helper Functions ---
def run_command(cmd, check=True, input_str=None, capture=False, cwd=None):
    """Safely run shell commands and handle errors."""
    try:
        result = subprocess.run(
            cmd,
            text=True,
            check=check,
            input=input_str,
            capture_output=capture,
            cwd=cwd,
        )
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error executing: {' '.join(cmd)}", file=sys.stderr)
        if capture:
            print(e.stderr, file=sys.stderr)
        sys.exit(e.returncode)


def command_exists(cmd):
    return shutil.which(cmd) is not None


# --- Core Installer Steps ---
def check_arch_linux():
    if not Path("/etc/arch-release").exists():
        print("This install script is designed for Arch Linux.", file=sys.stderr)
        print("Please install dependencies manually for your system.", file=sys.stderr)
        sys.exit(1)


def setup_aur_helper():
    """Check for yay/paru, or install one."""
    if command_exists("paru"):
        print(":: Found 'paru'. Using it as the AUR helper.")
        return "paru"
    elif command_exists("yay"):
        print(":: Found 'yay'. Using it as the AUR helper.")
        return "yay"

    print(":: No AUR helper found (paru or yay).")
    choice = (
        input("Which AUR helper would you like to install? (paru/yay/none): ")
        .strip()
        .lower()
    )

    if choice in ["paru", "yay"]:
        print(f":: Installing '{choice}'...")
        run_command(
            ["sudo", "pacman", "-S", "--needed", "--noconfirm", "git", "base-devel"]
        )

        with tempfile.TemporaryDirectory() as temp_dir:
            run_command(
                ["git", "clone", f"https://aur.archlinux.org/{choice}.git", temp_dir]
            )
            run_command(["makepkg", "-si", "--noconfirm"], cwd=temp_dir)

        print(f"-> '{choice}' has been installed successfully.")
        return choice

    print(":: Skipping AUR helper installation. Some packages may not be installed.")
    return None


def install_packages(helper):
    """Read packages.pkglist robustly and install."""
    pkglist_path = Path("packages.pkglist")
    if not pkglist_path.exists():
        print("Warning: packages.pkglist not found.", file=sys.stderr)
        return

    # Cleanly read the file, ignoring comments and empty lines
    with open(pkglist_path, "r") as f:
        packages = [
            line.strip() for line in f if line.strip() and not line.startswith("#")
        ]

    if packages:
        print(":: Installing packages...")
        # Cleanly pass packages as arguments, avoiding the stdin pipe issue
        cmd = [helper, "-S", "--needed", "--noconfirm"] + packages
        run_command(cmd)
        print("-> Package installation complete.")


def get_conflicting_files(stow_dir, target_home):
    conflicts = []

    # We want to traverse Stow dir similar to how stow does
    for root, _, files in os.walk(stow_dir):
        for file in files:
            # Full path in the repo
            repo_file_path = Path(root) / file

            # Calculate the relative path from the stow_dir root
            rel_path = repo_file_path.relative_to(stow_dir)

            # The target path in the home directory
            target_path = target_home / rel_path

            # If target exists or is a broken symlink
            if target_path.exists() or target_path.is_symlink():
                # Check if it's already symlinked to our repo file
                try:
                    if target_path.resolve() != repo_file_path.resolve():
                        conflicts.append(target_path)
                except FileNotFoundError:
                    # Broken symlink that isn't pointing to our file
                    conflicts.append(target_path)

    return conflicts


def backup_conflicting_files(stow_dir, target_home):
    """The improved backup logic with user confirmation."""
    print(":: Checking for conflicting dotfiles...")
    conflicts = get_conflicting_files(stow_dir, target_home)

    if not conflicts:
        print("No conflicting files found. Ready to stow.")
        return

    print("\nThe following conflicting files/directories were found:")
    for conflict in conflicts:
        print(f"  - {conflict}")

    print("")
    choice = (
        input("Do you want to back up these conflicting files? [Y/n]: ").strip().lower()
    )
    if choice not in ["n", "no"]:
        timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
        backup_root = target_home / f"backup_{timestamp}"
        print(f"Backing up conflicting files to {backup_root}...")
        for target in conflicts:
            try:
                rel_path = target.relative_to(target_home)
                backup_path = backup_root / rel_path
                backup_path.parent.mkdir(parents=True, exist_ok=True)

                print(f"Backing up {target} to {backup_path}")
                # Don't overwrite existing backups
                if not backup_path.exists():
                    shutil.move(str(target), str(backup_path))
            except Exception as e:
                print(f"Failed to backup {target}: {e}", file=sys.stderr)
    else:
        print("Removing conflicting files...")
        for target in conflicts:
            try:
                if target.is_symlink() or target.is_file():
                    target.unlink()
                elif target.is_dir():
                    shutil.rmtree(target)
                print(f"Removed {target}")
            except Exception as e:
                print(f"Failed to remove {target}: {e}", file=sys.stderr)


def deploy_dotfiles():
    """Deploy dotfiles using GNU Stow."""
    print(":: Stowing dotfiles...")
    target_home = str(Path.home())
    stow_dir = "dotfiles"
    run_command(["stow", "-v", "-t", target_home, stow_dir])


def delete_dotfiles():
    """Remove dotfiles symlinks using GNU Stow."""
    print(":: Removing dotfiles symlinks...")
    target_home = str(Path.home())
    stow_dir = "dotfiles"
    run_command(["stow", "-v", "-D", "-t", target_home, stow_dir])


def install_uosc():
    """Run the external UOSC installation script."""
    script_path = Path("scripts/install_uosc.sh")
    if script_path.exists() and os.access(script_path, os.X_OK):
        run_command([f"./{script_path}"])
    else:
        print(f"Warning: {script_path} not found or not executable.", file=sys.stderr)


def initialize_wallpapers():
    target_home = Path.home()

    print(":: Creating wallpaper directory...")
    default_wallpapers_dir = target_home / "Pictures" / "Wallpapers" / "Default"
    default_wallpapers_dir.mkdir(parents=True, exist_ok=True)

    default_wallpaper_src = Path("Wallpapers/default.jpeg")
    default_wallpaper_dst = default_wallpapers_dir / "default.jpeg"

    if default_wallpaper_src.exists() and not default_wallpaper_dst.exists():
        print(":: Copying default wallpaper...")
        shutil.copy2(default_wallpaper_src, default_wallpaper_dst)

    (target_home / "Pictures" / "Wallpapers" / "PUT_WALLPAPER_HERE").touch(
        exist_ok=True
    )

    print(":: Setting initial wallpaper symlink...")
    catalysthl_dir = target_home / ".local" / "share" / "CatalystHL"
    catalysthl_dir.mkdir(parents=True, exist_ok=True)

    current_wallpaper_symlink = catalysthl_dir / "current-wallpaper"
    if not current_wallpaper_symlink.exists():
        try:
            current_wallpaper_symlink.symlink_to(default_wallpaper_dst)
        except Exception as e:
            print(f"Warning: Failed to create symlink: {e}", file=sys.stderr)

    upwall_path = target_home / ".local" / "bin" / "upwall"
    if upwall_path.exists() and os.access(upwall_path, os.X_OK):
        print(":: Running upwall script to initialize wallpapers...")
        run_command([str(upwall_path)], check=False)
    else:
        print(
            f"Warning: upwall script not found or not executable at {upwall_path}.",
            file=sys.stderr,
        )
        print(
            "Wallpaper thumbnails and configuration may not be set up correctly.",
            file=sys.stderr,
        )


def main():
    parser = argparse.ArgumentParser(description="CatalystHL Dotfiles Installer")
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Remove the dotfile symlinks created by GNU Stow",
    )
    args = parser.parse_args()

    if args.delete:
        delete_dotfiles()
        print("\n-------------------------------------")
        print("Dotfiles uninstalled successfully.")
        print("-------------------------------------")
        sys.exit(0)

    check_arch_linux()
    helper = setup_aur_helper()

    if helper:
        install_packages(helper)
    else:
        print("Warning: Skipping package installation.", file=sys.stderr)

    backup_conflicting_files(Path("dotfiles"), Path.home())

    print(":: All dependencies satisfied. Deploying dotfiles using GNU Stow...")
    deploy_dotfiles()
    install_uosc()
    initialize_wallpapers()

    print("\n-------------------------------------")
    print("Installation complete!")
    print("It's recommended to restart your system.")
    print("-------------------------------------")


if __name__ == "__main__":
    main()
