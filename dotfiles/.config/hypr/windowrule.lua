hl.window_rule({
    name = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize"
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false
    },
    no_focus = true
})

hl.window_rule({
    name = "no-blur-chromium",
    match = { class = "^$", title = "^$" },
    no_blur = true
})

hl.window_rule({
    name = "xdg-desktop-portal-gtk",
    match = { class = "^[xX]dg-desktop-portal-gtk$" },
    float = true,
    center = true
})

hl.window_rule({
    name = "xdg-desktop-portal-hyprland",
    match = { class = "^xdg-desktop-portal-hyprland$" },
    float = true,
    center = true
})

hl.window_rule({
    name = "signin_popup",
    match = { class = "zen", title = "^Sign in - Google Accounts.*" },
    float = true,
    center = true
})

hl.window_rule({
    name = "imv",
    match = { class = "^imv$" },
    float = true,
    center = true
})

hl.window_rule({
    name = "nemo-opacity",
    match = { class = "^(nemo)$" },
    opacity = "0.8 override 0.8 override"
})

hl.window_rule({
    name = "blueberry",
    match = { class = "^(blueberry\\.py)$" },
    float = true,
    center = true
})

hl.layer_rule({
    name = "waybar-blur",
    match = { namespace = "waybar" },
    blur = true
})
hl.layer_rule({
    name = "waybar-ignore-alpha",
    match = { namespace = "waybar" },
    ignore_alpha = 0.0
})

hl.layer_rule({
    name = "rofi-ignore-alpha",
    match = { namespace = "rofi" },
    ignore_alpha = 0.0
})
hl.layer_rule({
    name = "rofi-blur",
    match = { namespace = "rofi" },
    blur = true
})
hl.layer_rule({
    name = "rofi-anim",
    match = { namespace = "rofi" },
    animation = "popin 85%"
})

hl.layer_rule({
    name = "swaync-notif-anim",
    match = { namespace = "swaync-notification-window" },
    animation = "slide right"
})
hl.layer_rule({
    name = "swaync-cc-blur",
    match = { namespace = "swaync-control-center" },
    blur = true
})
hl.layer_rule({
    name = "swaync-cc-ignore-alpha",
    match = { namespace = "swaync-control-center" },
    ignore_alpha = 0.0
})
hl.layer_rule({
    name = "swaync-cc-anim",
    match = { namespace = "swaync-control-center" },
    animation = "slide right"
})

hl.layer_rule({
    name = "selection-anim",
    match = { namespace = "selection" },
    animation = "fade"
})

hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "quickshell" },
    blur = true
})
hl.layer_rule({
    name = "quickshell-ignore-alpha",
    match = { namespace = "quickshell" },
    ignore_alpha = 0.0
})