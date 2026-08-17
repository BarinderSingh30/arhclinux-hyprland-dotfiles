-- conf/monitors.lua -- physical display layout
--
-- Current hardware:
--   eDP-1      1920x1080@60  ~14" laptop panel (157 DPI)
--   HDMI-A-1   1440x900@60   external
--
-- eDP-1 runs at 1.25x rather than the previous 1.5x: 1920/1.25 = 1536x864
-- logical pixels, a 20% gain in usable area over 1.5x's 1280x720, while
-- staying readable at this DPI. Both dimensions divide cleanly at 1.25,
-- so there is no fractional-pixel blurring.

local LAPTOP   = "eDP-1"
local EXTERNAL = "HDMI-A-1"

-- Layout: laptop on the BOTTOM, external to its TOP
hl.monitor({
    output   = LAPTOP,
    mode     = "1920x1080@60",
    position = "0x0",
    scale    = 1.25,
})

hl.monitor({
    output   = EXTERNAL,
    mode     = "1440x900@60",
    position = "0x-900",
    scale    = 1,
})

-- Fallback for any monitor plugged in later: sane defaults rather than nothing.
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

return {
    laptop   = LAPTOP,
    external = EXTERNAL,
}
