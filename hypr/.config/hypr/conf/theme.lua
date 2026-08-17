-- conf/theme.lua -- Tokyo Night
--
-- GENERATED FILE. Edited by `theme-set <palette>`, not by hand.
-- Source of truth: ~/dotfiles/theme-src/palettes/*.env
--
-- Every other module reads colors from here. Nothing else hardcodes a color,
-- which is what makes swapping the whole desktop theme a single command.

local M = {}

M.name = "tokyonight"

-- Base
M.bg            = "1a1b26"
M.bg_dark       = "16161e"
M.bg_highlight  = "292e42"
M.fg            = "c0caf5"
M.fg_dark       = "a9b1d6"
M.fg_gutter     = "3b4261"
M.comment       = "565f89"

-- Accents
M.blue          = "7aa2f7"
M.cyan          = "7dcfff"
M.magenta       = "bb9af7"
M.purple        = "9d7cd8"
M.orange        = "ff9e64"
M.yellow        = "e0af68"
M.green         = "9ece6a"
M.teal          = "73daca"
M.red           = "f7768e"

-- Semantic roles -- modules reference these, not the raw names above,
-- so a palette with different accent choices still slots in cleanly.
M.accent        = M.blue      -- focused window border, active workspace
M.accent_alt    = M.magenta   -- border gradient partner
M.inactive      = M.fg_gutter -- unfocused window border
M.urgent        = M.red

--- Build an rgba() string Hyprland accepts, from a hex triplet + alpha byte.
--- @param hex string  six-digit hex, no leading '#'
--- @param alpha string two-digit hex alpha (default "ff")
--- @return string
function M.rgba(hex, alpha)
    return "rgba(" .. hex .. (alpha or "ff") .. ")"
end

--- Same but opaque rgb().
--- @param hex string
--- @return string
function M.rgb(hex)
    return "rgb(" .. hex .. ")"
end

return M
