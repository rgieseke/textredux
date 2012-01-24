--[[--
This example shows the use of additional commands for a list, using the keys
table.

For the purpose of this example the `F6' key will be set to show the
example buffer. Provided that TextUI is installed, you can copy this to
your .textadept/init.lua, and press `F6` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
require 'textui'

local function show_action_list()
  local list = _M.textui.list.new('Action list')
  list.items = { 'one', 'two', 'three' }

  -- assign snapopen user home as a table command to f3
  list.keys.f3 = { _M.textadept.snapopen.open, _USERHOME }

  -- assign a closure to f4, which prints the list title to the statusbar
  list.keys.f4 = function(list)
    gui.statusbar_text = 'Command from ' .. list.title
  end

  -- print the currently selected item when f5 is pressed
  list.keys.f5 = function(list)
    gui.statusbar_text = 'Currently selected: ' .. tostring(list:get_current_selection())
  end

  list:show()
end

keys['f6'] = show_action_list
