-- conf/env.lua -- environment variables

-- Cursor. Kept at 24 because eDP-1 runs at 1.25x scale; the compositor
-- scales the cursor, so a larger base size would look oversized on HDMI-A-1 (1x).
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Force Wayland backends. Without these, Qt and Firefox silently fall back to
-- XWayland, which on a fractional-scaled display renders blurry.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("CLUTTER_BACKEND", "wayland")

-- Hardware video decode. Verified working on this machine via vainfo:
-- iHD driver, H.264 + HEVC (Main/Main10) + VP9 all hardware-decoded.
-- No AV1 -- Ice Lake (Gen11) predates AV1 decode, so AV1 streams fall back to CPU.
hl.env("LIBVA_DRIVER_NAME", "iHD")

-- Tell apps which desktop this is, so portals pick the right backend.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
