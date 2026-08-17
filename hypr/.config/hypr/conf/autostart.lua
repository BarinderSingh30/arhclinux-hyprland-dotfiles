-- conf/autostart.lua -- background processes, launched once on compositor start
--
-- Deliberately minimal right now: this file only starts things that are
-- actually installed. The stock config shipped binds for brightnessctl,
-- playerctl and hyprshutdown that were never installed, so those keys were
-- silently dead. Not repeating that mistake.
--
-- Phase 3 adds: waybar, hyprpaper, mako.
-- Phase 6 adds: cliphist watchers.

hl.on("hyprland.start", function()
    -- Polkit authentication agent: without this, any GUI action needing
    -- elevated privileges fails silently with no password prompt.
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
end)
