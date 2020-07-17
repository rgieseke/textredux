-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
Example on how to use custom styling with a TextUI buffer. This example shows
how to define custom styles and use them when inserting content.
]]

local M = {}

local textredux = require 'textredux'

local reduxstyle = textredux.core.style

-- define a custom style based on a default style
reduxstyle.example_style1 = reduxstyle.number..{underlined=true, bold=true}

-- define a custom style from scratch
reduxstyle.example_style2 = {italics = true, fore = '#0000ff', back='#ffffff'}

local function on_refresh(buffer)
  -- add some ordinary unstyled text. we can specify the newline directly here
  -- as '\n' since the buffer will always be in eol mode LF.
  buffer:add_text('Unstyled text\n')

  -- add some text using one the default styles from the user's theme
  buffer:add_text('Keyword style\n', reduxstyle.keyword)

  -- add some lines with custom styles
  buffer:add_text('Custom style based on default style\n',
                  reduxstyle.example_style1)
  buffer:add_text('Custom style from scratch',
                  reduxstyle.example_style2)
  buffer:add_text('\n')
end

function M.create_styled_buffer()
  local buffer = textredux.core.buffer.new('Example buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

return M
