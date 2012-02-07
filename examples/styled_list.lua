--[[--
This example shows how to use custom styling with the list class. It illustrates
both using one specific style for a column, and also how to specify styles
dynamically based on the item. For conciseness' sake there is no `on_selection`
handler specified.

For the purpose of this example the `F6' key will be set to show the
example buffer. Provided that TextUI is installed, you can copy this to
your .textadept/init.lua, and press `F6` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
_M.textui = require 'textui'

local style = _M.textui.style

-- define some custom styles for use with the list
style.example_red = { fore = '#FF0000' }
style.example_green = { fore = '#00FF00' }
style.example_blue = { fore = '#0000FF' }
style.example_code = { italic = true }

local function get_item_style(item, column_index)
  -- chose style based on the color name
  local color = item[1]
  if color == 'Red' then return style.example_red
  elseif color == 'Green' then return style.example_green
  elseif color == 'Blue' then return style.example_blue
  end
end

local function show_styled_list()
  local list = _M.textui.list.new('Styled list')
  list.headers = { 'Color', 'Code' }
  list.items = {
    { 'Red', '#FF0000' },
    { 'Blue',   '#0000FF' },
    { 'Green',  '#00FF00' }
  }
  -- specify the column styles; for the first column we'll determine the style
  -- to use dynamically, and for the second column we'll always use the custom
  -- style `style.example_code`.
  list.column_styles = { get_item_style, style.example_code }
  list:show()
end

keys['f6'] = show_styled_list
