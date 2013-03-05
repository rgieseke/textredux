--[[--
This example shows how to use custom styling with the list class. It illustrates
both using one specific style for a column, and also how to specify styles
dynamically based on the item. For conciseness' sake there is no `on_selection`
handler specified.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

_M.textredux = require 'textredux'

local M = {}

local tr_style = _M.textredux.core.style

-- define some custom styles for use with the list
tr_style.example_red = { fore = '#FF0000' }
tr_style.example_green = { fore = '#00FF00' }
tr_style.example_blue = { fore = '#0000FF' }
tr_style.example_code = { italic = true }

local function get_item_style(item, column_index)
  -- chose style based on the color name
  local color = item[1]
  if color == 'Red' then return tr_style.example_red
  elseif color == 'Green' then return tr_style.example_green
  elseif color == 'Blue' then return tr_style.example_blue
  end
end

function M.show_styled_list()
  local list = _M.textredux.core.list.new('Styled list')
  list.headers = { 'Color', 'Code' }
  list.items = {
    { 'Red', '#FF0000' },
    { 'Blue',   '#0000FF' },
    { 'Green',  '#00FF00' }
  }
  -- specify the column styles; for the first column we'll determine the style
  -- to use dynamically, and for the second column we'll always use the custom
  -- style `style.example_code`.
  list.column_styles = { get_item_style, tr_style.example_code }
  list:show()
end

return M
