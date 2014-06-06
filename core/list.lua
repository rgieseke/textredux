-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The list class provides a text based item listing for Textadept, featuring
advanced search capabilities and styling.

## How to use

Create the list using @{new}, specify @{items} and other fields/callbacks
(such as @{on_selection}) and invoke @{list:show}.

Please see also the various list examples in `./examples`.

## Features

- Support for multi-column table items, in addition to supporting the simpler
  case of just listing strings.
- Fully customizable styling. You can either specify individual styles for
  different columns, or specify styles for each item dynamically using a
  callback.
- Powerful search capabilities. The list class supports both exact matching and
  fuzzy matching, and will present best matches first. It also supports
  searching for multiple search strings (any text separated by whitespace is
  considered to be multiple search strings). Searches are done against all
  columns.
- `Ctrl/Alt/Meta-Backspace` resets the current search.

@module textredux.core.list
]]

local reduxstyle = require 'textredux.core.style'
local util_matcher = require 'textredux.util.matcher'

local string_rep = string.rep

local M = {}
local list = {}
reduxstyle.list_header = { fore = '#5E5E5E', underline = true }

reduxstyle.list_match_highlight = reduxstyle.number

--- The default style to use for diplaying headers.
-- This is by default the `style.list_header` style. It's possible to override
-- this for a specific list by assigning another value to the instance itself.
list.header_style = reduxstyle.list_header

--- The style to use for indicating matches.
-- You can turn off highlighing of matches by setting this to nil.
-- It's possible to override this for a specific list by assigning another
-- value to the instance itself. The default value is `style.default`.
list.match_highlight_style = reduxstyle.list_match_highlight

--- The default styles to use for different columns. This can be specified
-- individually for each list as well. Values can either be explicit styles,
-- defined using @{textredux.core.style}, or functions which returns
-- explicit styles. In the latter case, the function will be invoked with the
-- corresponding item and column index. The default styles contains styles for
-- up to three columns, after which the default style will be used.
list.column_styles = {}

--- Whether searches are case insensitive or not.
-- It's possible to override this for a specific list by assigning another
-- value to the instance itself. The default value is `true`.
list.search_case_insensitive = true

--- Whether fuzzy searching should be in addition to explicit matches.
-- It's possible to override this for a specific list by assigning another
-- value to the instance itself. The default value is `true`.
list.search_fuzzy = true

--- List instance fields.
-- These can be set only for a list instance, and not globally for the module.
-- @section instance

--- Optional headers for the list.
-- If set, the headers must be a table with the same number of columns as
-- @{items}.
list.headers = nil

--- A table of items to display in the list.
-- Each table item can either be a table itself, in which case the list will
-- be multi column, or a string in which case the list be single column.
list.items = nil

--[[- The handler/callback to call when the user has selected an item.
The handler will be passed the following parameters:

- `list`: the list itself
- `item`: the item selected
- `shift`: True if the Shift key was held down.
- `ctrl`: True if the Control key was held down.
- `alt`: True if the Alt/Option key was held down.
- `meta`: True if the Command/Meta key on Mac OS X/Curses was held down.
]]
list.on_selection = nil

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
list.on_new_selection = nil

--- The underlying @{textredux.core.buffer} used by the list.
list.buffer = nil

---
-- A table of key commands for the list.
-- This functions almost exactly the same as @{textredux.core.buffer.keys}.
-- The one difference is that for function values, the parameter passed will be
-- a reference to the list instead of a buffer reference.
list.keys = nil

--- A general purpose table that can be used for storing state associated
-- with the list. Just like @{textredux.core.buffer.data}, the `data` table
-- is special in the way that it will automatically be cleared whenever the user
-- closes the buffer associated with the list.
list.data = nil

--- @section end

--[[- Creates a new list.
@param title The list title
@param items The list items, see @{items}. Not required, items can be set later
using the @{items} field.
@param on_selection The on selection handler, see @{on_selection}. Not required,
this can be specified later using the @{on_selection} field.
@return The new list instance
]]
function M.new(title, items, on_selection)
  if not title then error('no title specified', 2) end
  local l = {
    title = title,
    items = items or {},
    on_selection = on_selection
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

--- Closes the list.
function list:close()
  self.buffer:close()
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

-- Return style for column from {@colum_styles} table.
function list:_column_style(item, column)
  local style = self.column_styles[column]
  if not style then return reduxstyle.default end
  return type(style) == 'function' and style(item, column) or style
end

-- Add text and padding.
local function add_column_text(buffer, text, pad_to, style)
  buffer:add_text(text, style)
  local padding = (pad_to + 1) - #text
  if padding then buffer:add_text(string_rep(' ', padding)) end
end

-- Highlight matches.
function highlight_matches(explanations, line_start, buffer, match_style)
  for _, explanation in ipairs(explanations) do
    for _, range in ipairs(explanation) do
      match_style:apply(
        line_start + range.start_pos - 1,
        range.length
      )
    end
  end
end

-- Add items.
function list:_add_items(items, start_index, end_index)
  local buffer = self.buffer
  local data = self.buffer.data
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
      "[..] (%d more items not shown, press <down> here to see more)",
      #items - end_index
    )
    buffer:add_text(message, reduxstyle.comment)
  end
end

-- Refresh list.
function list:_refresh()
  local buffer = self.buffer
  local data = buffer.data
  data.matching_items = data.matcher:match(data.search)

  -- Header.
  buffer:add_text(self.title .. ' : ')
  buffer:add_text(#data.matching_items, reduxstyle.number)
  buffer:add_text('/')
  buffer:add_text(#self.items, reduxstyle.number)
  buffer:add_text(' items')
  if data.search and #data.search > 0 then
    buffer:add_text( ' matching ')
    buffer:add_text(data.search, reduxstyle.comment)
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

-- Load more items.
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

-- Create Textredux buffer to display the list.
function list:_create_buffer()
  local reduxbuffer = textredux.core.buffer.new(self.title)
  reduxbuffer.on_refresh = function(...) self:_refresh(...) end
  reduxbuffer.on_deleted = function() self.data = {} end

  self.buffer = reduxbuffer
  self.data = self.buffer.data

  setmetatable(keys[reduxbuffer.keys_mode], {__index = function(t, k)
    if #k > 1 and k:find('^[cams]*.+$') then return keys[k] end
    if rawget(t, k) then return rawget(t, k) end
    local search = self.get_current_search(self) or ''
    self.set_current_search(self, search..k)
  end})

  reduxbuffer.keys['\b'] = function()
    local search = self.get_current_search(self)
    if search then self.set_current_search(self, search:sub(1, #search - 1)) end
  end

  local clear_search = function() self:set_current_search('') end
  reduxbuffer.keys['c\b'] = clear_search
  reduxbuffer.keys['a\b'] = clear_search
  reduxbuffer.keys['m\b'] = clear_search

  reduxbuffer.keys.down = function()
    if self.buffer.line_from_position(self, self.buffer.current_pos) >
       self.buffer.data.items_end_line and
       self.buffer.data.shown_items < #self.buffer.data.matching_items then
      self:_load_more_items()
    else
      buffer:line_down()
    end
  end

  local key_wrapper = function(t, k, v)
    if type(v) == 'function' then
      reduxbuffer.keys[k] = function() v(self) end
    else
      reduxbuffer.keys[k] = v
    end
  end

  self.keys = setmetatable({}, {
    __index = reduxbuffer.keys,
    __newindex = key_wrapper
  })
  return buffer
end

return M
