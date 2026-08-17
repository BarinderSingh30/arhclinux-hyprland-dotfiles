-- conf/binds.lua -- keybindings
--
-- Focus/movement stays on ARROW KEYS by request. hjkl is not bound, so the
-- keys remain free if you ever want to switch.
--
-- Every bind below references a binary that is actually installed. Verified:
-- kitty, dolphin, rofi, grim, slurp, brightnessctl, playerctl, hyprshutdown, wpctl.

local mod = "SUPER"

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"

--------------------------------------------------------------------------
-- Applications
--------------------------------------------------------------------------
hl.bind(mod .. " + Q", hl.dsp.exec_cmd(terminal),    { desc = "Terminal" })
hl.bind(mod .. " + E", hl.dsp.exec_cmd(fileManager), { desc = "File manager" })
hl.bind(mod .. " + R", hl.dsp.exec_cmd(menu),        { desc = "App launcher" })
hl.bind(mod .. " + M", hl.dsp.exec_cmd("hyprshutdown"), { desc = "Power menu" })

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
-- Screenshots (grim + slurp; both installed)
--   Phase 6 will add clipboard copy once wl-clipboard is in.
--------------------------------------------------------------------------
local shotdir = os.getenv("HOME") .. "/Pictures/Screenshots"
local stamp   = '$(date +%Y-%m-%d_%H-%M-%S).png'

hl.bind("PRINT",
    hl.dsp.exec_cmd('grim -g "$(slurp)" ' .. shotdir .. '/region_' .. stamp),
    { desc = "Screenshot: select region" })

hl.bind("SHIFT + PRINT",
    hl.dsp.exec_cmd('grim ' .. shotdir .. '/screen_' .. stamp),
    { desc = "Screenshot: whole output" })

--------------------------------------------------------------------------
-- Hardware keys
--   locked = true so they still work while the screen is locked.
--------------------------------------------------------------------------
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
