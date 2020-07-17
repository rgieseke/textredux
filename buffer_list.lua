-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The buffer list module provides a text based replacement for the standard
Textadept buffer list.

## Usage

Use the @{textredux.hijack} function or load the buffer list
in your `~/.textadept/init.lua`:

    local textredux = require('textredux')
    keys["ctrl+b"] = textredux.buffer_list.show

## Features

- Close a buffer from the buffer list (bound to `Ctrl + D` by default)
- Close all files in the directory of the selected buffer
  (bound to `Ctrl + Shift + D` and `Meta + D` in Curses by default)
- The list of buffers is sorted and the current buffer is pre-selected
- The buffers to show can be specified using a function

@module textredux.buffer_list
]]

local reduxlist = require 'textredux.core.list'

local M = {}

--- The Textredux list instance used by the buffer list.
M.list = nil

--[[-- The key bindings for the buffer list.

You can modifiy this to customise the key bindings to your liking. The key
bindings are passed directly to the Textredux list, so note that the
first argument to any function will be the Textredux list itself.
You can read more about the Textredux list's keys in the
[list documentation](./textredux.core.list.html#keys).

If you like to add a custom key binding for closing a buffer or files in a
directory you can bind the @{close_buffer} and @{close_directory} functions to a
key of your choice. For other actions it's likely that you want to obtain the
currently selected buffer - you can use the @{currently_selected_buffer}
function for that.
]]
M.keys = {
  ["ctrl+d"] = function(list) M.close_buffer(list) end, -- Default for `close buffer`
  [CURSES and 'meta+d' or 'ctrl+shif+d'] = function(list) M.close_directory(list) end
}

local buffer_source

local function shorten_home_dir(directory)
  if not directory then return end
  local home_dir = os.getenv('HOME') or os.getenv('UserProfile')
  return directory:gsub(home_dir, '~')
end

local function buffer_title(buffer)
  local title = (buffer.filename or ''):match('[\\/]([^/\\]+)$')
  return title or buffer.filename or buffer._type or _L['Untitled']
end

local function buffer_directory(buffer)
  if not buffer.filename then return nil end
  return shorten_home_dir(buffer.filename:match('^(.+[\\/])[^/\\]+$'))
end

local function get_buffer_items()
  local items = {}
  for _, buffer in ipairs(buffer_source()) do
    if M.list.buffer.target ~= buffer then
      local modified = buffer.modify and '*' or ''
      items[#items + 1] = {
        buffer_title(buffer) .. modified,
        buffer_directory(buffer),
        buffer = buffer
      }
    end
  end
  table.sort(items, function(a, b)
    if a[2] == b[2] then return a[1] < b[1] end
    if a[2] and b[2] then return a[2] < b[2] end
    return a[1] < b[1]
  end)
  return items
end

local function on_selection(list, item)
  list:close()
  local target = item.buffer
  if buffer ~= target then view:goto_buffer(target) end
end

--[[-- Returns the currently selected buffer in the list.
@param list The Textredux list instance used by the buffer list. If not
provided, then the global list is used automatically.
@return The currently selected buffer, if any.
@return The currently selected buffer's name, if any.
]]
function M.currently_selected_buffer(list)
  list = list or M.list
  if not list then error('`list` must be provided', 2) end
  local item = list:get_current_selection()
  if item then return item.buffer, item[1] end
end

--[[-- Closes the currently selected buffer in the buffer list.
@param list The Textredux list instance used by the buffer list. This function
is ordinarily invoked as the result of a key binding, and you should thus not
need to specify this yourself. If list isn't provided, the global list is
automatically used.
]]
function M.close_buffer(list)
  list = list or M.list
  if not list then error('`list` must be provided', 2) end
  local sel_buffer, name = M.currently_selected_buffer(list)
  if sel_buffer then
    ui.statusbar_text = 'Closing ' .. name .. '..'
    local current_pos = buffer.current_pos
    local current_search = list:get_current_search()
    view:goto_buffer(sel_buffer)
    local closed = sel_buffer:close()
    list.items = get_buffer_items()
    list:show()
    if closed then
      list:set_current_search(current_search)
      buffer.goto_pos(math.min(current_pos, buffer.length + 1))
      buffer.home()
      ui.statusbar_text = 'Closed ' .. name
    else
      ui.statusbar_text = ''
    end
  end
end

--[[-- Closes all files in the same directory as the currently selected buffer
in the buffer list.
@param list The Textredux list instance used by the buffer list. This function
is ordinarily invoked as the result of a key binding, and you should thus not
need to specify this yourself. If list isn't provided, the global list is
automatically used.
]]
function M.close_directory(list)
  list = list or M.list
  if not list then error('`list` must be provided', 2) end
  local sel_buffer, name = M.currently_selected_buffer(list)
  local dir = buffer_directory(sel_buffer)
  if dir then
    local closed
    for _, b in ipairs(_BUFFERS) do
      if buffer_directory(b) == dir then
        ui.statusbar_text = 'Closing ' .. name .. '..'
        local current_pos = buffer.current_pos
        local current_search = list:get_current_search()
        view:goto_buffer(b)
        closed = b:close()
        if not closed then
          ui.statusbar_text = 'Could not close file in '..dir
          break
        end
      end
    end
    if closed then
      ui.statusbar_text = 'Closed files in '..dir
    end
  end
  list.items = get_buffer_items()
  list:show()
end


--- Shows a list of the specified buffers, or _G.BUFFERS if not specified.
-- @param buffers Either nil, in which case all buffers within _G.BUFFERS
-- are displayed, or a function returning a table of buffers to display.
function M.show(buffers)
  buffer_source = buffers or function() return _BUFFERS end

  if not M.list then
    M.list = reduxlist.new('Buffer list')
    M.list.headers = {'Name', 'Directory'}
    M.list.on_selection = on_selection
    for k, v in pairs(M.keys) do
      M.list.keys[k] = v
    end
  end
  M.list.items = get_buffer_items()
  local buffer = buffer
  local active_buffer
  for index, item in ipairs(M.list.items) do
    if item.buffer == buffer then
      active_buffer = index
      break
    end
  end
  M.list:show()
  if active_buffer then
    local line = M.list.buffer.data.items_start_line + active_buffer
    M.list.buffer:goto_line(line - 1)
  end
  local short_cut = CURSES and '[Meta+D]' or '[Ctrl+Shift+D]'
  ui.statusbar_text = '[Enter] = open, [Ctrl+D] = close selected buffer, '..
    short_cut..' = close files in directory'
end


return M
