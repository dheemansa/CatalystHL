local colors = require("colors")

-- AUTOSTART
hl.on("hyprland.start", function () 
    hl.exec_cmd("waybar")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("swaync")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("lumi -i ~/.local/share/CatalystHL/current-wallpaper")
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
end)

-- ENVIRONMENT VARIABLES
hl.env("WALLPAPER_DIR", os.getenv("HOME") .. "/Pictures/Wallpapers")
hl.env("WALLPAPER_CACHE", os.getenv("HOME") .. "/.cache/wallpaper_thumbnails")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")

-- LOOK AND FEEL
hl.config({
    general = {
        gaps_in  = 3,
        gaps_out = 5,
        border_size = 2,

        col = {
            active_border   = colors.active_border,
            inactive_border = colors.inactive_border,
        },

        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 8,
        active_opacity = 1.0,
        inactive_opacity = 0.8,

        shadow = {
            enabled = false,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 4,
            ignore_opacity = true,
            new_optimizations = true,
            passes = 3,
            vibrancy = 0.1696,
        },
    },

    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    },

    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",

        follow_mouse = 1,
        sensitivity = 0,

        touchpad = {
            natural_scroll = true,
        },
    },
})

require("monitors")
require("animations")
require("keybinds")
require("windowrule")