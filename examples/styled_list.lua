-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
This example shows how to use custom styling with the list class. It illustrates
both using one specific style for a column, and also how to specify styles
dynamically based on the item. For conciseness' sake there is no `on_selection`
handler specified.
]]

local M = {}

local textredux = require 'textredux'

local reduxstyle = textredux.core.style

-- Define some custom styles for use with the list.
reduxstyle.example_red = {fore = '#FF0000'}
reduxstyle.example_green = {fore = '#00FF00'}
reduxstyle.example_blue = {fore = '#0000FF'}
reduxstyle.example_code = {italic = true}

local function get_item_style(item, column_index)
  -- Choose style based on the color name.
  local color = item[1]
  if color == 'Red' then return reduxstyle.example_red
  elseif color == 'Green' then return reduxstyle.example_green
  elseif color == 'Blue' then return reduxstyle.example_blue
  end
end

function M.show_styled_list()
  local list = textredux.core.list.new('Styled list')
  list.headers = {'Color', 'Code'}
  list.items = {
    {'Red', '#FF0000'},
    {'Blue', '#0000FF'},
    {'Green', '#00FF00'}
  }
  -- Specify the column styles; for the first column we'll determine the style
  -- to use dynamically, and for the second column we'll always use the custom
  -- style `style.example_code`.
  list.column_styles = { get_item_style, reduxstyle.example_code }
  list.match_highlight_style = reduxstyle.class
  list:show()
end

return M
