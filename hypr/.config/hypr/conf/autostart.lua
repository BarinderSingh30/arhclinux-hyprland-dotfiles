-- conf/autostart.lua -- background processes, launched once on compositor start
--
-- Only starts things that are actually installed. The stock config shipped
-- binds for brightnessctl, playerctl and hyprshutdown that were never
-- installed, so those keys were silently dead. Not repeating that mistake.
--
-- Deliberately NOT here: swaync. It ships D-Bus service files
-- (/usr/share/dbus-1/services/org.erikreider.swaync{,.cc}.service), so it is
-- activated on the first notification and costs nothing until then. Starting
-- it eagerly would just be a resident process waiting for work.
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

    -- Bluetooth applet. Two jobs, both of which were missing before:
    --
    --   1. The tray icon. Nothing else on this system publishes a Bluetooth
    --      StatusNotifierItem, so waybar's "tray" module had nothing to show.
    --      The icon only appeared after opening blueman-manager because the
    --      manager talks to org.blueman.Applet over D-Bus (main/DBusProxies.py),
    --      which D-Bus-activates the applet as a side effect.
    --
    --   2. Auto-connect. bluetoothd never initiates a connection to a paired
    --      BR/EDR device on its own -- it only accepts inbound ones -- so
    --      "Trusted: yes" alone reconnects nothing at boot. blueman's
    --      AutoConnect plugin calls Device.Connect() on startup, whenever the
    --      adapter powers on, and every 60s after that, for each device in
    --      `gsettings get org.blueman.plugins.autoconnect services`. That
    --      retry loop is why the earbuds connect whenever they leave the case,
    --      not only if they happen to be awake at boot.
    --
    -- blueman ships /usr/lib/systemd/user/blueman-applet.service, but it has
    -- no [Install] section, so `systemctl --user enable` has nothing to hook
    -- it to. Launched here instead, after waybar so the tray host exists first.
    -- Costs ~50 MB RSS -- the largest single item in this file.
    hl.exec_cmd("blueman-applet")

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
