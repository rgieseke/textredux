--[[
The color module provides utility functions for color handling.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textredux.util.matcher
]]

local M = {}

function M.string_to_color(rgb)
  if not rgb then return nil end
  local r, g, b = rgb:match('^#?(%x%x)(%x%x)(%x%x)$')
  if not r then error("Invalid color specification '" .. rgb .. "'", 2) end
  return tonumber(b .. g .. r, 16)
end

function M.color_to_string(color)
  local hex = string_format('%.6x', color)
  local b, g, r = hex:match('^(%x%x)(%x%x)(%x%x)$')
  if not r then return '?' end
  return '#' .. r .. g .. b
end

return M
