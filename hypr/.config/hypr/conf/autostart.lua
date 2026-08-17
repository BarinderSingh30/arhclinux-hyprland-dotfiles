-- conf/autostart.lua -- background processes, launched once on compositor start
--
-- Only starts things that are actually installed. The stock config shipped
-- binds for brightnessctl, playerctl and hyprshutdown that were never
-- installed, so those keys were silently dead. Not repeating that mistake.
--
-- Deliberately NOT here: mako. It ships a D-Bus service file
-- (/usr/share/dbus-1/services/fr.emersion.mako.service), so it is activated
-- on the first notification and costs nothing until then. Starting it
-- eagerly would just be a resident process waiting for work.
--
-- Phase 6 adds: cliphist watchers.

hl.on("hyprland.start", function()
    -- Polkit authentication agent: without this, any GUI action needing
    -- elevated privileges fails silently with no password prompt.
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    -- Wallpaper. Reads ~/.config/hypr/hyprpaper.conf, which theme-set
    -- generates along with the downscaled image it points at.
    hl.exec_cmd("hyprpaper")

    -- Bar. Two bar objects (eDP-1 and HDMI-A-1) live in one config file, so
    -- this single process drives both screens.
    hl.exec_cmd("waybar")

    -- Idle daemon: dim, lock, blank. Also the D-Bus listener that turns
    -- `loginctl lock-session` (SUPER+L, and lock-before-suspend) into an
    -- actual hyprlock. Reads ~/.config/hypr/hypridle.conf.
    hl.exec_cmd("hypridle")
end)
