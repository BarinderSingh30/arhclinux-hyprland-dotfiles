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
    match = { class = "^(org.kde.polkit-kde-authentication-agent-1|blueman-manager|nm-connection-editor|pavucontrol|pavucontrol-qt|wifi-qt)$" },
    float = true,
})

-- Plain alpha, no blur -- same call as kitty's TERM_OPACITY and waybar's
-- BAR_OPACITY (see theme-src/palettes/*.env): this machine's Iris Plus G1
-- makes blur a real per-frame cost, transparency without it is free.
hl.window_rule({
    name    = "qt-app-transparency",
    match   = { class = "^(pavucontrol-qt|wifi-qt)$" },
    opacity = "0.90 0.90",
})

-- Spotify: same plain-alpha treatment, no blur. Matched on the *lowercase*
-- class -- `spotify` is the native-Wayland class the client reports once
-- spotify/.config/spotify-flags.conf sets --ozone-platform=wayland. Under
-- XWayland it would report `Spotify` and this rule would silently miss.
--
-- The two numbers are "active inactive". Opacity here is a whole-surface
-- compositor effect, so album art and text go translucent along with the
-- chrome -- which is what sets the floor. 0.88 sits just below kitty's
-- TERM_OPACITY (0.92); by ~0.80 the wallpaper starts fighting the track list
-- and album thumbnails go muddy. Adjust in ~0.02 steps, `hyprctl reload`.
hl.window_rule({
    name    = "spotify-transparency",
    match   = { class = "^spotify$" },
    opacity = "0.88 0.88",
})

-- Waybar click target. Opens a TUI in a throwaway kitty window
-- (`kitty --class btop`), so it wants to float centered rather than resize
-- the tiled layout underneath it. (nmtui used to share this rule; the
-- network module now opens wifi-qt instead -- see float-utility-classes
-- and qt-app-transparency above.)
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
