--[[--
The indicator module provides support for indicators in your buffers.
Indicators lets you visually mark a certain text range using various styles and
colors, and using the event mechanism you can also receive events whenever the
user clicks the marked text.

The indicator definition
------------------------

An indicator is defined using a simple table with the properties listed below.
For the most part, these properties maps directly to fields in the
[buffer](http://foicica.com/textadept/api/buffer.html) class. The
list below will give short descriptions and refer to the corresponding field in
the buffer class where applicable.

- `style`: The style of the indicator. See `indic_style`.
- `alpha`: Alpha transparency value from 0 to 255 (or 256 for no alpha), used
   for fill colors of rectangles . See `indic_alpha`.
- `outline_alpha`: Alpha transparency value from 0 to 255 (or 256 for no alpha),
  used for outline colors of rectangles . See `indic_outline_alpha`.
- `fore`: The foreground color of the indicator. The color should be specified
  in the `'#rrggbb'` notation.
- `under`: Whether an indicator is drawn under text or over (default). Drawing
  under text works only when two phase drawing is enabled for the buffer (the
  default).

Using indicators
----------------

Start with defining your indicators using the format described above. You can
then  either apply them against a range of text using @{apply}, or pass them to
one of the text insertion functions in @{_M.textredux.ui.buffer}. If you need to
get the defined indicator number for an indicator, you can retrieve it using
@{number_for}. Please note that indicator numbers are not necessarily stable
between buffer switches, so problems may arise if you hold on to an indicator
number.

Please see the example @{buffer_indicators.lua} for some practical usage.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
@module _M.textredux.indicator
]]

local color = require 'textredux.util.color'

local constants = _SCINTILLA.constants
local _G = _G
local setmetatable, pairs = setmetatable, pairs

local M = {}
local _ENV = M
if setfenv then setfenv(1, _ENV) end

local indicators = setmetatable({}, {__mode = 'k' })

local function define_indicator(indicator, buffer)
  local buf_indics = indicators[buffer]
  if not buf_indics then
    indicators[buffer] = { next_number = constants.INDIC_MAX }
    buf_indics = indicators[buffer]
  end

  local number = buf_indics.next_number
  if number < 0 then error('Maximum number of indicators exceeded (32)') end

  if indicator.style then buffer.indic_style[number] = indicator.style end
  if indicator.alpha then buffer.indic_alpha[number] = indicator.alpha end
  if indicator.outline_alpha then
    buffer.indic_outline_alpha[number] = indicator.outline_alpha
  end
  if indicator.fore then
    buffer.indic_fore[number] = color.string_to_color(indicator.fore)
  end
  if indicator.under then buffer.indic_under[number] = indicator.under end
  buf_indics[indicator] = number
  buf_indics.next_number = buf_indics.next_number - 1
  return number
end

---  Defines the currently used custom indicators for the current buffer.
-- This must be called whenever a buffer with custom indicators is switched to.
-- This is automatically done by the @{_M.textredux.ui.buffer} class, and thus
-- not something you typically have to worry about.
function define_indicators()
  local buffer = _G.buffer
  local buf_indics = indicators[buffer] or {}
  indicators[buffer] = nil
  for indicator, _ in pairs(buf_indics) do
    define_indicator(indicator, buffer)
  end
end

--- Retrieves the indicator number used in the current buffer for the indicator.
-- @param indicator The indicator to retrieve the number for
function number_for(indicator)
  local buffer = _G.buffer
  local buf_indics = indicators[buffer] or {}
  return buf_indics[indicator] or define_indicator(indicator, buffer)
end

--- Applies the given indicator for the text range specified in the current
-- buffer.
-- @param indicator The indicator to apply
-- @param position The start position
-- @param length The length of the range to fill
function apply(indicator, position, length)
  local buffer = _G.buffer
  local number = number_for(indicator)
  buffer.indicator_current = number
  buffer:indicator_fill_range(position, length)
end

return M
