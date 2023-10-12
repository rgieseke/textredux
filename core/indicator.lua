-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The indicator module provides support for indicators in your buffers.
Indicators lets you visually mark a certain text range using various styles and
colors. Using the event mechanism you can also receive events whenever the
user clicks the marked text.

## The indicator definition

An indicator is defined using a simple table with the properties listed below.
For the most part, these properties maps directly to fields in the
[buffer](http://foicica.com/textadept/api/buffer.html) API.

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

A simple example:

    local reduxindicator = textredux.core.indicator
    reduxindicator.RED_BOX = {style = c.INDIC_BOX, fore = '#ff0000'}

## Using indicators

Start with defining your indicators using the format described above. You can
then either apply them against a range of text using apply, or pass them to
one of the text insertion functions in @{textredux.core.buffer}.

    local text = 'Text for a red box indicator\n\n'
    buffer:add_text(text)
    reduxindicator.RED_BOX:apply(0, #text)

    buffer:add_text(text, nil, nil, reduxindicator.RED_BOX)

Please also see the file `examples/buffer_indicators.lua`.

@module textredux.core.indicator
]]

local color = require 'textredux.util.color'

local M = {}

---
-- Applies the given indicator for the text range specified in the current
-- buffer.
-- @param self The indicator to apply
-- @param position The start position
-- @param length The length of the range to fill
local function apply(self, position, length)
  local buffer = buffer
  buffer.indicator_current = self.number
  buffer:indicator_fill_range(position, length)
end

-- Called when a new table is added to the indicator module.
local function define_indicator(t, name, properties)
  if not properties.number then
    local number = _SCINTILLA.new_indic_number()
    properties.number = number
  end
  properties.apply = apply
  rawset(t, name, properties)
end

-- Called to set indicator styles in a new buffer or view.
local function activate_indicators()
  local buffer = buffer
  for _, properties in pairs(M) do
    if type(properties) == 'table' then
      local number = properties.number
      if properties.style then buffer.indic_style[number] = properties.style end
      if properties.alpha then buffer.indic_alpha[number] = properties.alpha end
      if properties.outline_alpha then
        buffer.indic_outline_alpha[number] = properties.outline_alpha
      end
      if properties.fore then
        buffer.indic_fore[number] = color.string_to_color(properties.fore)
      end
      if properties.under then buffer.indic_under[number] = properties.under end
    end
  end
end

-- Ensure Textredux indicators are defined after switching buffers or views.
events.connect(events.BUFFER_NEW, activate_indicators)
events.connect(events.VIEW_NEW, activate_indicators)
events.connect(events.VIEW_AFTER_SWITCH, activate_indicators)

setmetatable(M, {__newindex=define_indicator})

return M
