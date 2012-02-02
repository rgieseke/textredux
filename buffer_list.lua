--[[--
@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textile.buffer_list
]]
local tui_list = require 'textui.list'
local keys = keys
local L = _L

local M = {}

local list, buffer_source

local function shorten_home_dir(directory)
  local home_dir = os.getenv('HOME') or os.getenv('UserProfile')
  return directory:gsub(home_dir, '~')
end

local function buffer_title(buffer)
  local title = (buffer.filename or ''):match('[\\/]([^/\\]+)$')
  return title or buffer.filename or buffer._type or L['untitled']
end

local function buffer_directory(buffer)
  if not buffer.filename then return nil end
  return shorten_home_dir(buffer.filename:match('^(.+[\\/])[^/\\]+$'))
end

local function get_buffer_items()
  local items = {}
  for _, buffer in ipairs(buffer_source()) do
    if list.buffer.target ~= buffer then
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

local function on_selection(list, item)
  list:close()
  view:goto_buffer(_BUFFERS[item.buffer])
end

local function close_buffer()
  local item = list:get_current_selection()
  if item then
    local name = item[1]
    gui.statusbar_text = 'Closing ' .. name .. '..'
    local current_pos = buffer.current_pos
    local current_search = list:get_current_search()
    view:goto_buffer(_BUFFERS[item.buffer])
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
-- are displayed, or a function returning a table of buffers.
function M.show(buffers)
  buffer_source = buffers or function() return _BUFFERS end

  if not list then
    list = tui_list.new('Buffer listing')
    list.headers = { 'Name', 'Directory' }
    list.on_selection = on_selection
    list.keys.esc = function() list:close() end
    list.keys.cd = close_buffer
    list.keys.esc = function() list:close() end
  end
  list.items = get_buffer_items()
  list:show()
end

return M
