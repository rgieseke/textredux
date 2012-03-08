--[[--
The buffer list module provides a text based replacement for the standard
Textadept buffer list. Two differences compared to the stock one is the ability
to close a buffer directly from the buffer list (bound to `Ctrl + d` by default),
and the option of specifying the buffers to list via a provided function.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textredux.buffer_list
]]
local tui_list = require 'textui.list'
local tr_gui = require 'textredux.gui'
local L = _L

local M = {}

--- The TextUI list instance used by the buffer list.
M.list = nil

--[[- The key bindings for the buffer list.

You can modifiy this to customise the key bindings to your liking. The key
bindings are passed directly to the TextUI list, so note that the
first argument to any function will be the TextUI list itself. You can read more
about the TextUI list's keys [here](http://nilnor.github.com/textui/docs/modules/_M.textui.list.html#keys).

If you like to add a custom key binding for closing a buffer you can bind the
@{close_buffer} function to a key of your choice. For other actions it's likely
that you want to obtain the currently selected buffer - you can use the
@{currently_selected_buffer} function for that.
]]
M.keys = {
  cd = function(list) M.close_buffer(list) end, -- Default binding for `close buffer`
  esc = function(list) list:close() end -- Escape closes list by default
}

local buffer_source

local function shorten_home_dir(directory)
  if not directory then return end
  local home_dir = os.getenv('HOME') or os.getenv('UserProfile')
  return directory:gsub(home_dir, '~')
end

local function buffer_title(buffer)
  local title = (buffer.filename or ''):match('[\\/]([^/\\]+)$')
  return title or buffer.filename or buffer._type or L['Untitled']
end

local function buffer_directory(buffer)
  if not buffer.filename then return nil end
  return shorten_home_dir(buffer.filename:match('^(.+[\\/])[^/\\]+$'))
end

local function get_buffer_items()
  local items = {}
  for _, buffer in ipairs(buffer_source()) do
    if M.list.buffer.target ~= buffer then
      local modified = buffer.dirty and '*' or ''
      items[#items + 1] = {
        buffer_title(buffer) .. modified,
        buffer_directory(buffer),
        buffer = buffer
      }
    end
  end
  return items
end

local function on_selection(list, item, shift, ctrl)
  list:close()
  if ctrl then tr_gui.switch_to_other_view() end
  view:goto_buffer(_BUFFERS[item.buffer])
end

--[[- Returns the currently selected buffer in the list.
@param list The TextUI list instance used by the buffer list. If not provided,
then the global list is used automatically.
@return The currently selected buffer, if any.
@return The currently selected buffer's name, if any.
]]
function M.currently_selected_buffer(list)
  list = list or M.list
  if not list then error('`list` must be provided', 2) end
  local item = list:get_current_selection()
  if item then return item.buffer, item[1] end
end

--[[- Closes the currently selected buffer in the buffer list.
@param list The TextUI list instance used by the buffer list. This function
is ordinarily invoked as the result of a key binding, and you should thus not need
to specify this yourself. If list isn't provided, the global list is automatically
used.
]]
function M.close_buffer(list)
  list = list or M.list
  if not list then error('`list` must be provided', 2) end
  local sel_buffer, name = M.currently_selected_buffer(list)
  if sel_buffer then
    gui.statusbar_text = 'Closing ' .. name .. '..'
    local current_pos = buffer.current_pos
    local current_search = list:get_current_search()
    view:goto_buffer(_BUFFERS[sel_buffer])
    local closed = buffer:close()
    list.items = get_buffer_items()
    list:show()
    if closed then
      list:set_current_search(current_search)
      buffer.goto_pos(math.min(current_pos, buffer.length))
      buffer.home()
      gui.statusbar_text = 'Closed ' .. name
    else
      gui.statusbar_text = ''
    end
  end
end

--- Shows a list of the specified buffers, or _G.BUFFERS it not specified.
-- @param buffers Either nil, in which case all buffers within _G.BUFFERS
-- are displayed, or a function returning a table of buffers to display.
function M.show(buffers)
  buffer_source = buffers or function() return _BUFFERS end

  if not M.list then
    M.list = tui_list.new('Buffer listing')
    M.list.headers = { 'Name', 'Directory' }
    M.list.on_selection = on_selection
    for k, v in pairs(M.keys) do
      M.list.keys[k] = v
    end
  end
  M.list.items = get_buffer_items()
  M.list:show()
  gui.statusbar_text = '[Enter] = open, [Ctrl+d] = close selected buffer'
end

return M
