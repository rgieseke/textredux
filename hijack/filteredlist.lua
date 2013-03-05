local list = require 'textredux.core.list'

local M = {}

local gui_filteredlist = gui.filteredlist
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

gui.filteredlist = function(title, columns, items, int_return, ...)
  if not current_coroutine then return gui_filteredlist(title, columns, items, int_return, ...) end
  local co = current_coroutine
  if columns then
    columns = type(columns) == 'string' and { columns } or columns
    if #columns > 1 then items = convert_multi_column_table(#columns, items) end
  end

  local l = list.new(title, items)
  if columns then l.headers = columns end
  l.keys.esc = function() l:close() end
  l.on_selection = function(l, item)
    local ret = int_return and index_of(item, items) - 1 or item
    l:close()
    coroutine.resume(co, ret)
  end
  l:show()
  return coroutine.yield()
end

function M.wrap(func)
  return function(...)
    current_coroutine = coroutine.create(func)
    local status, val = coroutine.resume(current_coroutine)
    current_coroutine = nil
    if not status then events.emit(events.ERROR, val) end
  end
end

return M
