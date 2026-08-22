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

local LAPTOP = "eDP-1"
local EXTERNAL = "HDMI-A-1"

-- Layout: laptop on the LEFT, external to its RIGHT
hl.monitor({
  output = LAPTOP,
  mode = "1920x1080@60",
  position = "0x0",
  scale = 1.25,
})

-- position is in logical (post-scale) layout space, not physical pixels:
-- eDP-1 is 1920 physical / 1.25 scale = 1536 logical wide, so the external
-- monitor must start at x=1536, not x=1920, or a dead zone opens between
-- them and the cursor can't cross into it.
hl.monitor({
  output = EXTERNAL,
  mode = "preferred",
  position = "1536x0",
  scale = 1,
})

-- Fallback for any monitor plugged in later: sane defaults rather than nothing.
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = "auto",
})

return {
  laptop = LAPTOP,
  external = EXTERNAL,
}
