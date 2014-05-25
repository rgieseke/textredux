-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
Example on how to use indicators with a Textredux buffer. This example shows
how to define custom indicators and apply them for selected text. Additionally,
available indicator styles are listed.
]]

local textredux = require 'textredux'
local reduxstyle = require 'textredux.core.style'

local M = {}

local c = _SCINTILLA.constants
local indicator = textredux.core.indicator

indicator.RED_BOX = {style = c.INDIC_BOX, fore = '#ff0000'}
indicator.BLUE_FILL = {style = c.INDIC_ROUNDBOX, fore = '#0000ff'}

local indicator_styles = {
  INDIC_PLAIN = 'An underline',
  INDIC_SQUIGGLE = 'A squiggly underline 3 pixels in height',
  INDIC_TT = 'An underline of small `T` shapes',
  INDIC_DIAGONAL = 'An underline of diagonal hatches',
  INDIC_STRIKE = 'Strike out',
  INDIC_HIDDEN =  'Invisible - no visual effect',
  INDIC_BOX = 'A rectangular bounding box',
  INDIC_ROUNDBOX = 'A translucent box with rounded corners around the text',
  INDIC_STRAIGHTBOX = 'Similar to INDIC_ROUNDBOX but with sharp corners',
  INDIC_DASH = 'A dashed underline',
  INDIC_DOTS = 'A dotted underline',
  INDIC_SQUIGGLELOW = 'A squiggly underline 2 pixels in height',
  INDIC_DOTBOX = 'Similar to INDIC_STRAIGHTBOX but with a dotted outline',
  INDIC_SQUIGGLEPIXMAP = 'Identical to INDIC_SQUIGGLE but draws faster by using\n'..
    'a pixmap instead of multiple line segments',
  INDIC_COMPOSITIONTHICK = 'A 2-pixel thick underline at the bottom of the line\n'..
    'inset by 1 pixel on on either side. Similar in appearance to Asian\n'..
    'language input composition'
}
 for k, v in pairs(indicator_styles) do
  indicator[k] = {style = c[k]}
end

local function on_refresh(buffer)
  buffer:add_text('Indicators:\n\n')

  local start_pos = buffer.current_pos
  buffer:add_text('Text for manual red box indicator\n\n')
  indicator.RED_BOX:apply(start_pos, buffer.current_pos - start_pos)

  buffer:add_text('Text for buffer inserted blue indicator\n\n',
                  nil, nil, indicator.BLUE_FILL)

  buffer:add_text('Indicator styles:\n\n')

  for k, v in pairs(indicator_styles) do
    buffer:add_text(k, nil, nil, indicator[k])
    buffer:add_text('\n'..v..'\n\n')
  end

end

function M.create_indicator_buffer()
  local buffer = textredux.core.buffer.new('Indicator buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

return M
