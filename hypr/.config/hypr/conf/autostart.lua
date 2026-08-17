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

    -- Clipboard history recorders. Wayland has no clipboard daemon of its
    -- own: the clipboard belongs to the window that copied, and its contents
    -- die with that window. wl-paste --watch subscribes to selection changes
    -- and hands each one to `cliphist store`, which is what makes SUPER+
    -- SHIFT+V able to show anything at all.
    --
    -- TWO watchers, not one. wl-paste with no --type picks whichever MIME the
    -- source advertises first, which for an image copied out of a browser is
    -- often some HTML wrapper rather than the image. Splitting them means
    -- text is stored as text and images as images. The cost is one extra
    -- process of a couple of MB.
    --
    -- cliphist ships /usr/lib/systemd/user/cliphist.service, which would give
    -- supervision and restart-on-failure. It CANNOT be used here: that unit
    -- declares `Requisite=graphical-session.target`, and this session does not
    -- run under uwsm, so that target is never activated --
    --
    --   $ systemctl --user is-active graphical-session.target
    --   inactive
    --
    -- Requisite means "fail if this is not already active", so the unit would
    -- refuse to start. It also only launches the single untyped watcher.
    -- Revisit if the session ever moves to uwsm (see system/greetd/config.toml).
    hl.exec_cmd("wl-paste --type text  --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)
