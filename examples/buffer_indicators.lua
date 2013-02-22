--[[--
Example on how to use indicators with a Textredux buffer. This example shows
how to define custom indicators and apply them for selected text.

For the purpose of this example `Ctrl+3' will be set to show the
example buffer. Provided that Textredux is installed, you can run this
example by pasting `require 'textredux.examples.buffer_indicators'` into the
`Command entry` and then press `Ctrl+3` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
_M.textredu = require 'textredux'

local c = _SCINTILLA.constants
local indicator = _M.textredux.indicator

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

local function create_indicator_buffer()
  local buffer = _M.textredux.buffer.new('Indicator buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

keys['c3'] = create_indicator_buffer
