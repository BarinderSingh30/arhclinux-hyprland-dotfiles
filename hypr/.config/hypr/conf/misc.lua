-- conf/misc.lua -- compositor behaviour that isn't input, looks, or rules
--
-- Note: `vfr` is NOT set here. It moved to `debug.vfr` in this version and is
-- already on by default -- setting it as `misc.vfr` is a config error.

local t = require("conf.theme")

hl.config({
    misc = {
        -- hyprpaper owns the wallpaper; no built-in logo or splash.
        force_default_wallpaper  = 0,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,

        -- Matches the theme, so empty workspaces and the moment before the
        -- wallpaper loads don't flash a default color.
        background_color = t.rgb(t.bg),

        -- Keep focus predictable when windows request activation.
        focus_on_activate          = true,
        mouse_move_focuses_monitor = true,

        -- Terminal swallowing was on (launching a GUI app from kitty hid the
        -- terminal until the app exited), but that meant the terminal you
        -- ran e.g. blueman-manager from would disappear the moment it
        -- popped up -- turned off by request: no window should hide just
        -- because another one opened.
        enable_swallow = false,

        -- Warn when an app stops responding rather than leaving a frozen window.
        enable_anr_dialog = true,

        -- Suppress Hyprland's fractional-scaling overlay, which fires because
        -- eDP-1 runs at 1.25x. Compositor notice about our own config change;
        -- it repeats and says nothing actionable. Does not affect app
        -- notifications, which go through the D-Bus daemon (dunst -> mako).
        disable_scale_notification = true,
    },

    general = {
        -- Snap floating windows to edges and to each other.
        snap = {
            enabled     = true,
            window_gap  = 10,
            monitor_gap = 10,
        },
    },
})
