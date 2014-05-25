-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
Example on how to use custom styling with a TextUI buffer. This example shows
how to define custom styles and use them when inserting content.
]]

textredux = require 'textredux'

local M = {}

local tr_style = textredux.core.style

-- define a custom style based on a default style
tr_style.example_style1 = tr_style.string .. { underline = true }

-- define a custom style from scratch
tr_style.example_style2 = { italic = true, fore = '#680000' }

local function on_refresh(buffer)
  -- add some ordinary unstyled text. we can specify the newline directly here
  -- as '\n' since the buffer will always be in eol mode LF.
  buffer:add_text('Unstyled text\n')

  -- add some text using one the default styles from the user's theme
  buffer:add_text('Keyword style\n', tr_style.keyword)

  -- add some lines with custom styles
  buffer:add_text('Custom style based on default style\n',
                  tr_style.example_style1)
  buffer:add_text('Custom style from scratch\n',
                  tr_style.example_style2)
end

function M.create_styled_buffer()
  local buffer = textredux.core.buffer.new('Example buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

return M
