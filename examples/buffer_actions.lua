-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
Example on various ways to make the buffer interactive, that is responding to
user input. This example illustrates the use of implicit and explicit hotspots
using either function or table commands, as well as key commands and responding
directly to key presses.
]]

local M = {}

local textredux = require 'textredux'

local reduxstyle = textredux.core.style
reduxstyle.action_style = reduxstyle['function']..{underlined = true}

local function on_refresh(buffer)
  buffer:add_text('Press Ctrl-T to show a message box.')
  buffer:add_text('\n\n')
  buffer:add_text('Table command: ')
  buffer:add_text('Quickopen Textadept config directory', reduxstyle.action_style,
                  { io.quick_open, _USERHOME })

  buffer:add_text('\n\nExplicit hotspot: ')
  local start_pos = buffer.current_pos
  buffer:add_text('Click here somewhere\nto show the command selection list',
                  reduxstyle.action_style)
  buffer:add_hotspot(start_pos, buffer.current_pos, textadept.menu.select_command)
end

function M.create_action_buffer()
  local buffer = textredux.core.buffer.new('Action buffer')
  buffer.on_refresh = on_refresh

  -- Bind Control+T to show a simple message box.
  buffer.keys['ctrl+t'] = function()
    ui.dialogs.msgbox{title='Testredux', text='Test 1, 2, 3!'}
  end

  buffer:show()
end

return M
