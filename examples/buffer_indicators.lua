--[[--
Example on how to use indicators with a TextUI buffer. This example shows
how to define custom indicators and apply them for selected text.

For the purpose of this example the `F6' key will be set to show the
example buffer. Provided that TextUI is installed, you can copy this to
your .textadept/init.lua, and press `F6` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
_M.textui = require 'textui'

local c = _SCINTILLA.constants
local indicator = _M.textui.indicator

local indic_red_box = { style = c.INDIC_BOX, fore = '#ff0000' }
local indic_blue_fill = { style = c.INDIC_ROUNDBOX, fore = '#0000ff' }

local function on_refresh(buffer)
  buffer:add_text('Indicators:\n\n')

  local start_pos = buffer.current_pos
  buffer:add_text('Text for manual red box indicator\n\n')
  indicator.apply(indic_red_box, start_pos, buffer.current_pos - start_pos)

  buffer:add_text('Text for buffer inserted blue indicator\n', nil, nil, indic_blue_fill)
end

local function create_indicator_buffer()
  local buffer = _M.textui.buffer.new('Indicator buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

keys['f6'] = create_indicator_buffer
