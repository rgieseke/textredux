-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
This example shows how to use the list with multi column items. It also
illustrates the optional use of headers, as well as the fact that the
`on_selection` callback will be passed the item exactly as it was given
which lets you use any arbitrary field in the selection logic.
]]

local M = {}

local textredux = require 'textredux'
local reduxstyle = textredux.core.style

local function on_selection(list, item)
  -- We will get back exactly what we specified, so the code below will print
  -- the IDs we specify further down (1, 2 or 3)
  ui.statusbar_text = 'You selected ' .. item.id
end

function M.show_multi_column_list()
  local list = textredux.core.list.new('Multi column list')

  -- Set the headers. This is optional and can be skipped if so desired
  list.headers = { 'Thing', 'Is' }

  -- List of multi column items, with additional named fields
  list.items = {
    {'Volvo', 'Vehicle', id = 1},
    {'Dog', 'Animal', id = 2},
    {'Hell','Other people', id = 3}
  }
  list.column_styles = {reduxstyle.number, reduxstyle.operator}
  list.on_selection = on_selection
  list:show()
end

return M
