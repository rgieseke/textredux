--[[--
Very basic example on how to use the list class.

For the purpose of this example the `F6' key will be set to show the
example buffer. Provided that TextUI is installed, you can copy this to
your .textadept/init.lua, and press `F6` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
_M.textui = require 'textui'

local function show_simple_list()
  -- create the list
  local list = _M.textui.list.new(
    'Simple list', -- list title
    { 'one', 'two', 'three' }, -- list items
    function (list, item) -- on selection callback
      gui.statusbar_text = 'You selected ' .. item
    end
  )

  -- and show the list
  list:show()
end

keys['f6'] = show_simple_list
