--[[--
This example shows the use of additional commands for a list, using the keys
table.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

textredux = require 'textredux'

local M = {}

function M.show_action_list()
  local list = textredux.core.list.new('Action list (press "4", "5", "6")')
  list.items = { 'one', 'two', 'three' }

  -- assign snapopen user home as a table command to `3`
  list.keys['4'] = { io.snapopen, _USERHOME }

  -- assign a closure to `5`, which prints the list title to the statusbar
  list.keys['5'] = function(list)
    ui.statusbar_text = 'A command from ' .. list.title
  end

  -- print the currently selected item when `6` is pressed
  list.keys['6'] = function(list)
    ui.statusbar_text = 'Currently selected: ' ..
                          tostring(list:get_current_selection())
  end
  list:show()
end

return M
