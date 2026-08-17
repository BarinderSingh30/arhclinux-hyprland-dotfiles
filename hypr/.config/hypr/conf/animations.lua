-- conf/animations.lua -- short and snappy
--
-- Hyprland animation "speed" is in deciseconds: speed = 3 means 300ms.
-- Target here is roughly 150ms for window motion -- fast enough to feel
-- instant, slow enough to track what moved. Nothing decorative.

hl.config({
    animations = {
        enabled = true,
    },
})

-- Curves
hl.curve("snap",     { type = "bezier", points = { {0.2, 0.9}, {0.1, 1.0} } })
hl.curve("easeOut",  { type = "bezier", points = { {0.16, 1},  {0.3,  1} } })
hl.curve("linear",   { type = "bezier", points = { {0, 0},     {1, 1} } })

hl.animation({ leaf = "global",        enabled = true, speed = 1.5, bezier = "snap" })

-- Windows
hl.animation({ leaf = "windows",       enabled = true, speed = 1.5, bezier = "snap" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 1.5, bezier = "snap",    style = "popin 92%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.2, bezier = "linear",  style = "popin 92%" })
hl.animation({ leaf = "border",        enabled = true, speed = 2.0, bezier = "easeOut" })

-- Fades: kept very short; long fades are the main thing that makes a WM feel sluggish
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.0, bezier = "linear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.0, bezier = "linear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 1.0, bezier = "linear" })

-- Layers (bar, launcher, notifications)
hl.animation({ leaf = "layers",        enabled = true, speed = 1.5, bezier = "easeOut" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 1.5, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.2, bezier = "linear",  style = "fade" })

-- Workspace switching: slide, quick
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.5, bezier = "snap",    style = "slide" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.5, bezier = "snap",    style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.5, bezier = "snap",    style = "slide" })
