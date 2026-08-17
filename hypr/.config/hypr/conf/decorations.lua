-- conf/decorations.lua -- borders, gaps, rounding, effects
--
-- Design brief: "crisp and fast", explicitly NO rounded corners.
-- So: rounding 0, shadows off, blur off. On an Iris Plus G1 every blur pass
-- costs real frame time, and none of it is wanted here anyway.

local t = require("conf.theme")

hl.config({
    general = {
        gaps_in     = 4,
        gaps_out    = 8,
        border_size = 2,

        col = {
            -- Focused window: accent gradient at 45deg.
            -- For a flatter look, replace the whole table with: t.rgb(t.accent)
            active_border = {
                colors = { t.rgba(t.accent, "ee"), t.rgba(t.accent_alt, "ee") },
                angle  = 45,
            },
            inactive_border = t.rgba(t.inactive, "aa"),
        },

        resize_on_border = true,   -- grab any border/gap to resize
        allow_tearing    = false,
        layout           = "dwindle",
    },

    decoration = {
        rounding       = 0,   -- sharp corners, as specified
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
        },

        -- decoration.glow is new in this Hyprland version (stub line 1396):
        -- an accent halo around the focused window. It suits sharp corners and
        -- is cheaper than blur. Off by default -- flip `enabled` to try it.
        glow = {
            enabled        = false,
            range          = 8,
            render_power   = 2,
            color          = t.rgba(t.accent, "60"),
            color_inactive = t.rgba(t.inactive, "00"),
        },

        -- Subtle darkening of unfocused windows. Off to stay crisp; set
        -- dim_inactive = true if you want stronger focus separation.
        dim_inactive = false,
        dim_strength = 0.15,
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },

    master = {
        new_status = "master",
    },
})
