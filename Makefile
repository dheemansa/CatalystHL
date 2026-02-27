# Makefile for managing dotfiles using GNU Stow
# This makefile simplifies the process of creating and removing symlinks
# for configuration files in the repository.

# Target directory for configuration files (user's home directory)
TARGET_HOME := $(HOME)
STOW_DIR := dotfiles

.PHONY: all stow delete backup create-wallpaper-dir init-symlink

# Default target: runs the 'stow' target
all: stow

# Creates symlinks for all dotfiles
stow: backup create-wallpaper-dir
	@echo "Stowing dotfiles..."
	@stow -v -t $(TARGET_HOME) $(STOW_DIR)
	@$(MAKE) init-symlink

# Backs up existing files that would conflict with stow
# Finds all files in the STOW_DIR and checks if they exist in TARGET_HOME and are not symlinks
backup:
	@echo "Backing up conflicting files and folders..."
	@timestamp=$$(date +%Y-%m-%d_%H-%M-%S); \
	for rel_path in $$(cd $(STOW_DIR) && find . -mindepth 1 -maxdepth 3 \( -path "./.config/*" -o -path "./.local/bin/*" -o -path "./.local/share/*" -o -name ".*" \) -not -name ".config" -not -name ".local" -not -path "./.local/bin" -not -path "./.local/share"); do \
		rel_path="$${rel_path#./}"; \
		target="$(TARGET_HOME)/$$rel_path"; \
		repo_item="$(STOW_DIR)/$$rel_path"; \
		if [ -e "$$target" ] || [ -L "$$target" ]; then \
			src_abs=$$(readlink -f "$$repo_item"); \
			target_abs=$$(readlink -f "$$target"); \
			if [ "$$src_abs" != "$$target_abs" ]; then \
				echo "Backing up $$target to $$target.$$timestamp.bak"; \
				mv -n "$$target" "$$target.$$timestamp.bak" 2>/dev/null || true; \
			fi; \
		fi; \
	done

# Removes the symlinks created by stow
delete:
	@echo "Removing stow symlinks..."
	@stow -v -D -t $(TARGET_HOME) $(STOW_DIR)

# Creates the Pictures/Wallpapers directory in the home directory
create-wallpaper-dir:
	@echo "Creating wallpaper directory..."
	@mkdir -p $(TARGET_HOME)/Pictures/Wallpapers/Default
	@echo "Copying default wallpaper..."
	@cp -n Wallpapers/default.jpeg $(TARGET_HOME)/Pictures/Wallpapers/Default/default.jpeg || true
	@touch $(TARGET_HOME)/Pictures/Wallpapers/PUT_WALLPAPER_HERE

# Creates a symlink to the default wallpaper if one doesn't already exist
init-symlink:
	@echo "Setting initial wallpaper symlink..."
	@mkdir -p $(TARGET_HOME)/.local/share/CatalystHL
	@if [ ! -e $(TARGET_HOME)/.local/share/CatalystHL/current-wallpaper ]; then \
		ln -s $(TARGET_HOME)/Pictures/Wallpapers/Default/default.jpeg $(TARGET_HOME)/.local/share/CatalystHL/current-wallpaper; \
	fi
