--[[--
Example on how to use indicators with a Textredux buffer. This example shows
how to define custom indicators and apply them for selected text.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

local textredux = require 'textredux'

local M = {}

local c = _SCINTILLA.constants
local indicator = textredux.core.indicator

local indic_red_box = { style = c.INDIC_BOX, fore = '#ff0000' }
local indic_blue_fill = { style = c.INDIC_ROUNDBOX, fore = '#0000ff' }

local function on_refresh(buffer)
  buffer:add_text('Indicators:\n\n')

  local start_pos = buffer.current_pos
  buffer:add_text('Text for manual red box indicator\n\n')
  indicator.apply(indic_red_box, start_pos, buffer.current_pos - start_pos)

  buffer:add_text('Text for buffer inserted blue indicator\n',
                  nil, nil, indic_blue_fill)
end

function M.create_indicator_buffer()
  local buffer = textredux.core.buffer.new('Indicator buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

return M
