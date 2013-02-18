--[[--
Example on various ways to make the buffer interactive, i.e. responding to user
input. This example illustrates the use of implicit and explicit hotspots using
either function or table commands, as well as key commands and responding
directly to key presses.

For the purpose of this example `Ctrl+3' will be set to show the
example buffer. Provided that Textredux is installed, you can run this
example by pasting `require 'textredux.examples.buffer_actions'` into the
`Command entry` and then press `Ctrl+3` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
_M.textredux = require 'textredux'

local style = _M.textredux.style
style.action_style = { back = '#6e6e6e', fore = '#00FFFF' }

local function on_refresh(buffer)
  buffer:add_text('Function command: ')
  buffer:add_text('Show modifiers',
                  style.action_style, function(buffer, shift, ctl, alt, meta)
    local modifiers = ''
    if shift then modifiers = modifiers .. ' shift' end
    if ctl then modifiers = modifiers .. ' control' end
    if alt then modifiers = modifiers .. ' alt' end
    if meta then modifiers = modifiers .. ' meta' end
    gui.statusbar_text = "Selected with modifiers: " .. modifiers
  end)

  buffer:add_text('\nTable command: ')
  buffer:add_text('Snapopen user home', style.action_style,
                  { _M.textadept.snapopen.open, _USERHOME })

  buffer:add_text('\n\nExplicit hotspot: ')
  local start_pos = buffer.current_pos
  buffer:add_text('Click here somewhere\nto select a theme',
                  style.action_style)
  buffer:add_hotspot(start_pos, buffer.current_pos, gui.select_theme)
end

local function on_keypress(buffer, key, code, shift, ctl, alt, meta)
  -- print all lowercase characters to the statusbar
  if key and string.match(key, '^[a-z]$') then
    gui.statusbar_text = key
    return true
  end
end

local function create_action_buffer()
  local buffer = _M.textredux.buffer.new('Action buffer')
  buffer.on_refresh = on_refresh
  buffer.on_keypress = on_keypress

  -- bind Control C to 'select command'
  buffer.keys.cc = _M.textadept.menu.select_command

  buffer:show()
end

keys['c3'] = create_action_buffer
