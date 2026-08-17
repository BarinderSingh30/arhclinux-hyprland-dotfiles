-- conf/binds.lua -- keybindings
--
-- Focus/movement stays on ARROW KEYS by request. hjkl is not bound, so the
-- keys remain free if you ever want to switch.
--
-- Every bind below references a binary that is actually installed. Verified:
-- kitty, dolphin, rofi, hyprshot, hyprpicker, cliphist, brightnessctl,
-- playerctl, hyprshutdown, wpctl.

local mod = "SUPER"

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"

-- Scripts from this repo must be called by ABSOLUTE path.
--
-- Hyprland does not spawn commands through a login shell, so ~/.zshenv never
-- runs and ~/.local/bin is not on the PATH. Verified by reading the
-- environment of a running Hyprland child:
--
--   $ tr '\0' '\n' < /proc/$(pgrep -x waybar)/environ | grep ^PATH=
--   PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:...
--
-- A bare `clip-menu` here would fail silently -- the key would simply do
-- nothing, with no error anywhere. Everything else bound in this file lives
-- in /usr/bin and is fine unqualified.
local bin = os.getenv("HOME") .. "/.local/bin/"

--------------------------------------------------------------------------
-- Applications
--------------------------------------------------------------------------
hl.bind(mod .. " + Q", hl.dsp.exec_cmd(terminal),    { desc = "Terminal" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "File manager" })
hl.bind(mod .. " + R", hl.dsp.exec_cmd(menu),        { desc = "App launcher" })
hl.bind(mod .. " + M", hl.dsp.exec_cmd("hyprshutdown"), { desc = "Power menu" })

-- Lock. Goes through loginctl rather than calling hyprlock directly so logind
-- marks the session locked; hypridle receives the resulting Lock signal and
-- runs its lock_cmd, whose `pidof` guard stops a second hyprlock stacking on
-- the first. NOTE this bind therefore depends on hypridle running -- it is
-- started in conf/autostart.lua. If you ever remove it from there, change
-- this bind to "hyprlock" or the key goes silently dead.
hl.bind(mod .. " + L", hl.dsp.exec_cmd("loginctl lock-session"), { desc = "Lock screen" })

--------------------------------------------------------------------------
-- Window management
--------------------------------------------------------------------------
hl.bind(mod .. " + C",         hl.dsp.window.close(),                     { desc = "Close window" })
hl.bind(mod .. " + V",         hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle float" })
hl.bind(mod .. " + F",         hl.dsp.window.fullscreen(),                { desc = "Fullscreen" })
hl.bind(mod .. " + P",         hl.dsp.window.pseudo(),                    { desc = "Pseudo tile" })
hl.bind(mod .. " + J",         hl.dsp.layout("togglesplit"),              { desc = "Toggle split direction" })
hl.bind(mod .. " + SHIFT + C", hl.dsp.window.center(),                    { desc = "Center floating window" })

-- Focus (arrow keys)
hl.bind(mod .. " + left",  hl.dsp.focus({ direction = "left" }),  { desc = "Focus left" })
hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }), { desc = "Focus right" })
hl.bind(mod .. " + up",    hl.dsp.focus({ direction = "up" }),    { desc = "Focus up" })
hl.bind(mod .. " + down",  hl.dsp.focus({ direction = "down" }),  { desc = "Focus down" })

-- Move window (SHIFT + arrow keys)
hl.bind(mod .. " + SHIFT + left",  hl.dsp.window.move({ direction = "left" }),  { desc = "Move window left" })
hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }), { desc = "Move window right" })
hl.bind(mod .. " + SHIFT + up",    hl.dsp.window.move({ direction = "up" }),    { desc = "Move window up" })
hl.bind(mod .. " + SHIFT + down",  hl.dsp.window.move({ direction = "down" }),  { desc = "Move window down" })

-- Mouse drag/resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------------------------------------------------------------
-- Workspaces
--   1-5  live on HDMI-A-1, 6-10 on eDP-1 (see conf/workspaces.lua),
--   so a given number always lands on the same physical screen.
--------------------------------------------------------------------------
for i = 1, 10 do
    local key = i % 10   -- workspace 10 is bound to the "0" key
    hl.bind(mod .. " + " .. key,         hl.dsp.focus({ workspace = i }),       { desc = "Workspace " .. i })
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), { desc = "Move to workspace " .. i })
end

-- Scratchpad
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"),              { desc = "Toggle scratchpad" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }),   { desc = "Send to scratchpad" })

-- Cycle workspaces with the scroll wheel
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

--------------------------------------------------------------------------
-- Screenshots (hyprshot -- a wrapper around the grim/slurp pair this used
-- to call directly)
--
-- What hyprshot adds over raw `grim -g "$(slurp)"`:
--   * a window mode, which picks a window by its real geometry instead of
--     making you drag a rectangle and hope you got the border
--   * it saves AND copies to the clipboard in one go
--   * -z freezes the screen while you select, so you can capture an open
--      menu or a hover state -- those vanish the moment slurp takes over
--      otherwise. This is why hyprpicker is installed: hyprshot lists it as
--      an optional dependency and uses it to paint the frozen overlay.
--
-- -o is passed explicitly. Left alone, hyprshot falls back to
-- XDG_PICTURES_DIR and would drop files loose in ~/Pictures (read out of the
-- shipped script: `[ -z "$HYPRSHOT_DIR" ] && SAVEDIR=${XDG_PICTURES_DIR:=~}`).
-- It mkdir -p's the directory itself, so the folder needs no setup.
--------------------------------------------------------------------------
local shotdir = os.getenv("HOME") .. "/Pictures/Screenshots"
local shot    = "hyprshot -z -o " .. shotdir

hl.bind("PRINT",         hl.dsp.exec_cmd(shot .. " -m region"), { desc = "Screenshot: region" })
hl.bind("SUPER + PRINT", hl.dsp.exec_cmd(shot .. " -m window"), { desc = "Screenshot: window" })
hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd(shot .. " -m output"), { desc = "Screenshot: whole screen" })

-- Clipboard only -- nothing hits the disk. For pasting a quick crop into a
-- chat window without leaving a file behind to tidy up later.
hl.bind("CTRL + PRINT",
    hl.dsp.exec_cmd(shot .. " -m region --clipboard-only"),
    { desc = "Screenshot: region to clipboard only" })

--------------------------------------------------------------------------
-- Clipboard history, color picker, cheatsheet
--------------------------------------------------------------------------
-- Everything ever copied, searchable. Requires the wl-paste watchers started
-- in conf/autostart.lua -- without them the picker opens empty.
hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd(bin .. "clip-menu"),
    { desc = "Clipboard history" })

-- Eyedropper. -a copies the hex straight to the clipboard, -l keeps it
-- lowercase (#7aa2f7, matching how the palettes are written), -n pops a
-- notification so there is feedback that something was actually picked.
-- The result lands in the clipboard, so cliphist records it too.
hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("hyprpicker -a -l -n"),
    { desc = "Pick a color (hex to clipboard)" })

-- Menu of reference sheets: these binds, the zsh keys and aliases, and the
-- yazi keymap. Each one is generated from the live thing it documents rather
-- than written down, so none of them can go stale. See scripts/cheatsheet.
hl.bind(mod .. " + slash", hl.dsp.exec_cmd(bin .. "cheatsheet"),
    { desc = "Cheatsheets (hyprland / zsh / yazi)" })

--------------------------------------------------------------------------
-- Hardware keys
--   locked = true so they still work while the screen is locked.
--
--   Each carries a desc purely so it shows up in the cheatsheet. That script
--   only lists binds that have one, and "which key mutes the mic" is exactly
--   the sort of thing worth being able to look up.
--------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true, desc = "Volume up" })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true, desc = "Volume down" })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, desc = "Mute audio" })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, desc = "Mute microphone" })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true, desc = "Brightness up" })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true, desc = "Brightness down" })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true, desc = "Media: next track" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Media: play/pause" })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, desc = "Media: play/pause" })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true, desc = "Media: previous track" })
