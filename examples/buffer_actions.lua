-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
Example on various ways to make the buffer interactive, that is responding to
user input. This example illustrates the use of implicit and explicit hotspots
using either function or table commands, as well as key commands and responding
directly to key presses.
]]

textredux = require 'textredux'

local M = {}

local tr_style = textredux.core.style
tr_style.action_style = { back = '#6e6e6e', fore = '#00FFFF' }

local function on_refresh(buffer)
  buffer:add_text('Table command: ')
  buffer:add_text('Snapopen user home', tr_style.action_style,
                  { io.snapopen, _USERHOME })

  buffer:add_text('\n\nExplicit hotspot: ')
  local start_pos = buffer.current_pos
  buffer:add_text('Click here somewhere\nto select a command',
                  tr_style.action_style)
  buffer:add_hotspot(start_pos, buffer.current_pos, textadept.menu.select_command)
end

function M.create_action_buffer()
  local buffer = textredux.core.buffer.new('Action buffer')
  buffer.on_refresh = on_refresh

  -- bind Control+T to simple message box
  buffer.keys.ct = function()
    ui.dialogs.msgbox{title='Testing', text='Test 1, 2, 3 …'}
  end

  buffer:show()
end

return M
