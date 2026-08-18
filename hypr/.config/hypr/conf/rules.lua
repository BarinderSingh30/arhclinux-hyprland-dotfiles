-- conf/rules.lua -- window and layer rules

-- Ignore maximize requests from applications; the tiler decides geometry.
hl.window_rule({
    name           = "suppress-maximize-events",
    match          = { class = ".*" },
    suppress_event = "maximize",
})

-- Fixes drag-and-drop from XWayland clients (kept from the stock config).
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Dialogs and pickers float rather than tiling into the layout.
hl.window_rule({
    name  = "float-dialogs",
    match = { title = "^(Open File|Save File|Save As|Open Folder|Choose Files|Select a File)" },
    float = true,
})

hl.window_rule({
    name  = "float-utility-classes",
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1|blueman-manager|nm-connection-editor|pavucontrol)$" },
    float = true,
})

-- Waybar click target. Opens a TUI in a throwaway kitty window
-- (`kitty --class btop`), so it wants to float centered rather than resize
-- the tiled layout underneath it. (nmtui used to share this rule; the
-- network module now opens scripts/.local/bin/wifi-menu in rofi instead,
-- which floats on its own via rofi's own window config.)
hl.window_rule({
    name   = "float-tui-popups",
    match  = { class = "^(btop)$" },
    float  = true,
    center = true,
    size   = "960 640",
})

-- Picture-in-picture: float, pin above everything, park bottom-right.
hl.window_rule({
    name  = "pip",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    move  = "monitor_w-660 monitor_h-400",
})

-- Firefox sharing indicator is a tiny always-on-top strip; keep it out of the way.
hl.window_rule({
    name  = "firefox-sharing-indicator",
    match = { title = "Firefox — Sharing Indicator" },
    float = true,
})
