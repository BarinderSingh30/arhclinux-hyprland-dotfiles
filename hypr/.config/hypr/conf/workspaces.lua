-- conf/workspaces.lua -- bind workspaces to monitors
--
-- Workspaces 1-5  -> HDMI-A-1 (external)
-- Workspaces 6-10 -> eDP-1    (laptop)
--
-- persistent = true keeps each workspace alive even when empty, so the bar
-- always shows the full set and SUPER+<n> always lands on the same screen
-- regardless of what is currently open.
--
-- Field names (monitor / default / persistent) confirmed against
-- /usr/share/hypr/stubs/hl.meta.lua lines 603-622.

local monitors = require("conf.monitors")

local EXTERNAL_WS = { 1, 2, 3, 4, 5 }
local LAPTOP_WS   = { 6, 7, 8, 9, 10 }

for _, ws in ipairs(EXTERNAL_WS) do
    hl.workspace_rule({
        workspace  = tostring(ws),
        monitor    = monitors.external,
        persistent = true,
        -- first workspace of the set is the one the monitor shows on connect
        default    = (ws == EXTERNAL_WS[1]),
    })
end

for _, ws in ipairs(LAPTOP_WS) do
    hl.workspace_rule({
        workspace  = tostring(ws),
        monitor    = monitors.laptop,
        persistent = true,
        default    = (ws == LAPTOP_WS[1]),
    })
end
