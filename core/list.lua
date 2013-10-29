--[[--
The list class provides a versatile and extensible text based item listing for
Textadept, featuring advanced search capabilities and styling. It's a
convenient way of presenting lists to the user for simple selection, but is
equally well suited for creating advanced list based interfaces.

Features at a glance
--------------------

- Support for multi-column table items, in addition to supporting the simpler
  case of just listing strings.
- Fully customizable styling. You can either specify individual styles for
  different columns, or specify styles for each item dynamically using a
  callback. If you do neither, you will automatically get sane defaults.
- Powerful search capabilities. The list class supports both exact matching and
  fuzzy matching, and will present best matches first. It also supports
  searching for multiple search strings (any text separated by whitespace is
  considered to be multiple search strings). Searches are done against all
  columns.

How to use
----------

Create the list using @{new}, specify @{items} and other fields/callbacks
(such as @{on_selection}) and invoke @{list:show}.

Please see the various list examples for more hands-on instructions.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module textredux.core.list
]]

local style = require 'textredux.core.style'
local textredux_buffer = require 'textredux.core.buffer'
local util_matcher = require 'textredux.util.matcher'

local _G, textredux, string, table, keys, math =
      _G, textredux, string, table, keys, math
local ipairs, error, type, setmetatable, select, tostring =
      ipairs, error, type, setmetatable, select, tostring
local string_rep = string.rep

local list = {}
local _ENV = list
if setfenv then setfenv(1, _ENV) end

style.list_header = { fore = '#5E5E5E', underline = true }
style.list_match_highlight = style.default

--- The default style to use for diplaying headers.
-- This is by default the `style.list_header` style. It's possible to override
-- this for a specific list by assigning another value to the instance itself.
header_style = style.list_header

--- The style to use for indicating matches.
-- You can turn off highlighing of matches by setting this to nil.
-- It's possible to override this for a specific list by assigning another
-- value to the instance itself. The default value is `style.default`.
match_highlight_style = style.list_match_highlight

--- The default styles to use for different columns. This can be specified
-- individually for each list as well. Values can either be explicit styles,
-- defined using @{textredux.core.style}, or functions which returns
-- explicit styles. In the latter case, the function will be invoked with the
-- corresponding item and column index. The default styles contains styles for
-- up to three columns, after which the default style will be used.
column_styles = nil

-- I fought LDoc, but LDoc won. Define the field separately here to avoid it
-- being poorly documented as a table
column_styles =  {
  style.string,
  style.comment,
  style.operator,
}

--- Whether searches are case insensitive or not.
-- It's possible to override this for a specific list by assigning another
-- value to the instance itself. The default value is `true`.
search_case_insensitive = true

--- Whether fuzzy searching should be in addition to explicit matches.
-- It's possible to override this for a specific list by assigning another
-- value to the instance itself. The default value is `true`.
search_fuzzy = true

--- List instance fields.
-- These can be set only for a list instance, and not globally for the module.
-- @section instance

--- Optional headers for the list.
-- If set, the headers must be a table with the same number of columns as
-- @{items}.
headers = nil

--- A table of items to display in the list.
-- Each table item can either be a table itself, in which case the list will
-- be multi column, or a string in which case the list be single column.
items = nil

--[[- The handler/callback to call when the user has selected an item.
The handler will be passed the following parameters:

- `list`: the list itself
- `item`: the item selected
- `shift`: True if the Shift key was held down.
- `ctrl`: True if the Control key was held down.
- `alt`: True if the Alt/Option key was held down.
- `meta`: True if the Command/Meta key on Mac OS X/Curses was held down.
]]
on_selection = nil

--[[- The handler/callback to call when the user has typed in text which
doesn't match any item, and presses `<enter>`.

The handler will be passed the following parameters:

- `list`: the list itself
- `search`: the current search of the list
- `shift`: True if the Shift key was held down.
- `ctrl`: True if the Control key was held down.
- `alt`: True if the Alt/Option key was held down.
- `meta`: True if the Command/Meta key on Mac OS X/Curses was held down.
]]
on_new_selection = nil

--- The underlying @{textredux.core.buffer} used by the list.
buffer = nil

---
-- A table of key commands for the list.
-- This functions almost exactly the same as @{textredux.core.buffer.keys}.
-- The one difference is that for function values, the parameter passed will be
-- a reference to the list instead of a buffer reference.
keys = nil

--- Callback invoked whenever the list receives a keypress.
-- This functions almost exactly the sames as
-- @{textredux.core.buffer.on_keypress}.
-- The one difference is that for function values, the first parameter passed
-- will be a reference to the list instead of a buffer reference.
--
-- Please note that by overriding this it's possible to block any key presses
-- from ever reaching the list itself.
-- @see keys
on_keypress = nil

--- A general purpose table that can be used for storing state associated
-- with the list. Just like @{textredux.core.buffer.data}, the `data` table
-- is special in the way that it will automatically be cleared whenever the user
-- closes the buffer associated with the list.
data = nil

--- @section end

--[[- Creates a new list.
@param title The list title
@param items The list items, see @{items}. Not required, items can be set later
using the @{items} field.
@param on_selection The on selection handler, see @{on_selection}. Not required,
this can be specified later using the @{on_selection} field.
@return The new list instance
]]
function new(title, items, on_selection)
  if not title then error('no title specified', 2) end
  local _column_styles = {}
  setmetatable(_column_styles, { __index = column_styles })
  local l = {
    title = title,
    items = items or {},
    on_selection = on_selection,
    column_styles = _column_styles,
    data = {},
  }
  setmetatable(l, { __index = list })
  l:_create_buffer()
  return l
end

--- Shows the list.
function list:show()
  self:_calculate_column_widths()
  self.buffer.data = {
    matcher = util_matcher.new(
                self.items,
                self.search_case_insensitive,
                self.search_fuzzy
              )
  }
  self.buffer:set_title(self.title)
  self.buffer:show()
end

--- Closes the list.
function list:close()
  self.buffer:delete()
end

--- Returns the currently selected item if any, or nil otherwise.
function list:get_current_selection()
  local buffer = self.buffer
  if buffer:is_showing() then
    local data = buffer.data
    local current_line = buffer:line_from_position(buffer.current_pos)
    if current_line >= data.items_start_line and current_line <= data.items_end_line then
      return data.matching_items[current_line - data.items_start_line + 1]
    end
  end
  return nil
end

--- Returns the current user search if any, or nil otherwise.
function list:get_current_search()
  local search = self.buffer.data.search
  return search and #search > 0 and search or nil
end

--- Sets the current user search.
-- @param search The search string to use
function list:set_current_search(search)
  self.buffer.data.search = search
  if self.buffer:is_active() then self.buffer:refresh() end
end

-- Begin private section.

-- Calculates the column widths for the current items.
function list:_calculate_column_widths()
  local column_widths = {}

  for i, header in ipairs(self.headers or {}) do
    column_widths[i] = #tostring(header)
  end
  for i, item in ipairs(self.items) do
    if type(item) ~= 'table' then item = {item} end
    for j, field in ipairs(item) do
      column_widths[j] = math.max(column_widths[j] or 0, #tostring(field))
    end
  end
  self._column_widths = column_widths
end

function list:_column_style(item, column)
  local style = self.column_styles[column]
  if not style then return style.default end
  return type(style) == 'function' and style(item, column) or style
end

local function add_column_text(buffer, text, pad_to, style)
  buffer:add_text(text, style)
  local padding = (pad_to + 1) - #text
  if padding then buffer:add_text(string_rep(' ', padding)) end
end

function highlight_matches(explanations, line_start, buffer, match_style)
  for _, explanation in ipairs(explanations) do
    for _, range in ipairs(explanation) do
      style.apply(match_style,
                  buffer,
                  line_start + range.start_pos - 1,
                  range.length)
    end
  end
end

function list:_add_items(items, start_index, end_index)
  local buffer = self.buffer
  local data = buffer.data
  local search = data.search
  local column_widths = self._column_widths

  for index = start_index, end_index do
    local item = items[index]
    if item == nil or index > end_index then break end
    local columns = type(item) == 'table' and item or { item }
    local line_start = buffer.current_pos
    for j, field in ipairs(columns) do
      local pad_to = j == nr_columns and 0 or column_widths[j]
      add_column_text(buffer, tostring(field),
                      pad_to, self:_column_style(columns, j))
    end

    if self.match_highlight_style then
      local explanations = data.matcher:explain(search, buffer:get_cur_line())
      highlight_matches(explanations, line_start, buffer,
                        self.match_highlight_style)
    end

    buffer:add_text('\n')
    if self.on_selection then
      local handler = function (buffer, shift, ctrl, alt, meta)
        self.on_selection(self, item, shift, ctrl, alt, meta)
      end
      buffer:add_hotspot(line_start, buffer.current_pos, handler)
    end
  end
  data.shown_items = end_index
  data.items_end_line = buffer:line_from_position(buffer.current_pos) - 1

  if #items > end_index then
    local message = string.format(
      "[..] (%d more items not shown, press <pagedown>/<down> here to see more)",
      #items - end_index
    )
    buffer:add_text(message, style.comment)
  end
end

function list:_refresh()
  local buffer = self.buffer
  local data = buffer.data
  data.matching_items = data.matcher:match(data.search)

  -- Header.
  buffer:add_text(self.title .. ' : ')
  buffer:add_text(#data.matching_items, style.number)
  buffer:add_text('/')
  buffer:add_text(#self.items, style.number)
  buffer:add_text(' items')
  if data.search and #data.search > 0 then
    buffer:add_text( ' matching ')
    buffer:add_text(data.search, style.comment)
  end
  buffer:add_text('\n\n')

  -- Item listing.
  local column_widths = self._column_widths
  local nr_columns = #column_widths

  -- Headers.
  local headers = self.headers
  if headers then
    for i, header in ipairs(self.headers or {}) do
      local pad_to = i == nr_columns and 0 or column_widths[i]
      add_column_text(buffer, header, pad_to, self.header_style)
    end
    buffer:add_text('\n')
  end

  -- Items.
  data.items_start_line = buffer:line_from_position(buffer.current_pos)
  local nr_items = buffer.lines_on_screen - data.items_start_line - 1
  self:_add_items(data.matching_items, 1, nr_items)
  buffer:goto_line(data.items_start_line)
  buffer:home()
end

function list:_load_more_items()
  local buffer = self.buffer
  local data = buffer.data
  local start_index = data.shown_items + 1
  local end_index = start_index + buffer.lines_on_screen - 3
  buffer:goto_pos(buffer.length)
  buffer:home()

  buffer:update(function()
    buffer:del_line_right()
    self:_add_items(data.matching_items, start_index, end_index)
  end)
  buffer:goto_pos(buffer.length)
end

function list:_on_keypress(buffer, key, code, shift, ctl, alt, meta)
  if self.on_keypress then
    local result = self.on_keypress(self, key, code, shift, ctl, alt, meta)
    if result then return result end
  end

  if not key then return end
  local data = buffer.data
  local search = data.search or ''

  if buffer:line_from_position(buffer.current_pos) > data.items_end_line and
     data.shown_items < #data.matching_items and
     (key == 'down' or key == 'pgdn' or key == 'kpdown' or key == 'kppgdn')
  then
    self:_load_more_items()
    return true
  elseif key:match('\n$') then
    if #search > 1 and self.on_new_selection then
      self.on_new_selection(self, search, shift, ctl, alt, meta)
      return true
    end
  elseif #key == 1 and not key:match('^%c$') then
    search = search .. key
  elseif key == '\b' then
    if search == '' then return end
    search = search:sub(1, -2)
  else
    return
  end
  buffer.data.search = search
  self.buffer:refresh()
  return true
end

function list:_create_buffer()
  local buffer = textredux_buffer.new(self.title)
  buffer.on_refresh = function(...) self:_refresh(...) end
  buffer.on_keypress = function(...) return self:_on_keypress(...) end
  buffer.on_deleted = function() self.data = {} end
  self.buffer = buffer

  local key_wrapper = function(t, k, v)
    if type(v) == 'function' then
      buffer.keys[k] = function() v(self) end
    else
      buffer.keys[k] = v
    end
  end

  self.keys = setmetatable({}, { __index = buffer.keys,
                                 __newindex = key_wrapper })
  return buffer
end

return list
