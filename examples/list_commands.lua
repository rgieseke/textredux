-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
This example shows the use of additional commands for a list, using the keys
table.
]]

local M = {}

local textredux = require 'textredux'

function M.show_action_list()
  local list = textredux.core.list.new(
    'List with additional commands (press "4", "5", "6")')
  list.items = {'one', 'two', 'three'}

  -- Assign snapopen user home as a table command to `3`.
  list.keys['4'] = { io.snapopen, _USERHOME }

  -- Assign a closure to `5`, which prints the list title to the statusbar.
  list.keys['5'] = function(list)
    ui.statusbar_text = 'A command from ' .. list.title
  end

  -- Print the currently selected item when `6` is pressed.
  list.keys['6'] = function(list)
    ui.statusbar_text = 'Currently selected: ' ..
      tostring(list:get_current_selection())
  end
  list:show()
end

return M
