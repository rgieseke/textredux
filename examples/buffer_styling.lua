--[[--
Example on how to use custom styling with a TextUI buffer. This example shows
how to define custom styles and use them when inserting content.

For the purpose of this example the `F6' key will be set to show the
example buffer. Provided that TextUI is installed, you can copy this to
your .textadept/init.lua, and press `F6` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
require 'textui'

local style = _M.textui.style

-- define a custom style based on a default style
style.example_style1 = style.string .. { underline = true }

-- define a custom style from scratch
style.example_style2 = { italic = true, fore = '#680000' }

local function on_refresh(buffer)
  -- add some ordinary unstyled text. we can specify the newline directly here
  -- as '\n' since the buffer will always be in eol mode LF.
  buffer:add_text('Unstyled text\n')

  -- add some text using one the default styles from the user's theme
  buffer:add_text('Keyword style\n', style.keyword)

  -- add some lines with custom styles
  buffer:add_text('Custom style based on default style\n', style.example_style1)
  buffer:add_text('Custom style from scratch\n', style.example_style2)
end

local function create_styled_buffer()
  local buffer = _M.textui.buffer.new('Example buffer')
  buffer.on_refresh = on_refresh
  buffer:show()
end

keys['f6'] = create_styled_buffer
