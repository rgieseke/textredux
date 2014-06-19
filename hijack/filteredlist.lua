--[[
Filtered list wrapper.
]]

local list = require 'textredux.core.list'
local tr_style = require 'textredux.core.style'

local M = {}

local ui_filteredlist = ui.dialogs.filteredlist
local current_coroutine

local function convert_multi_column_table(nr_columns, items)
  local _items, _item = {}, {}
  for i, item in ipairs(items) do
    _item[#_item + 1] = item
    if i % nr_columns == 0 then
      _items[#_items + 1] = _item
      _item = {}
    end
  end
  return _items
end

local function index_of(element, table)
  for i, e  in ipairs(table) do
    if e == element then return i end
  end
end

ui.dialogs.filteredlist = function(options)
  if not current_coroutine then
    return ui_filteredlist(options)
  end
  local co = current_coroutine
  local title = options.title or ''
  local columns = options.columns
  local items = options.items or {}
  if columns then
    columns = type(columns) == 'string' and { columns } or columns
    if #columns > 1 then items = convert_multi_column_table(#columns, items) end
  end

  local l = list.new(title, items)
  if columns then l.headers = columns end
  l.on_selection = function(l, item)
    local value = not options.string_output and index_of(item, items) or item
    l:close()
    coroutine.resume(co, 1, value)
  end
  l:show()
  return coroutine.yield()
end

-- Wrap
function M.wrap(func)
  return function(...)
    current_coroutine = coroutine.create(func)
    local status, val = coroutine.resume(current_coroutine)
    current_coroutine = nil
    if not status then events.emit(events.ERROR, val) end
  end
end

return M
