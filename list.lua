--[[--
The list class provides a versatile and extensible text based item listing for
TextAdept, featuring advanced search capabilities and styling. It's a convinient
way of presenting lists to the user for simple selection, but can also just
as well be used to construct more elaborate list based interfaces.

Features at a glance
--------------------

- Support for multi-column table items, in addition to supporting the the simpler
  case of just listing strings.
- Fully customizable styling. You can either specify individual styles for
  different columns, or specify styles for each item dynamically using a callback.
  If you do neither, you will automatically get sane defaults.
- Type to narrow searching. The list class supports both exact matching and fuzzy
  matching, and will present best matches first. It also supports searching for
  multiple search strings (any text separated by whitespace is considered to
  be multiple search strings). Searches are done against all columns.

How to use
----------

Create the list using @{new}, specify @{items} and other fields/callbacks
(such as @{on_selection}) and invoke @{list:show}.

Please see the various list examples for more hands on instructions.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textui.list
]]

local style = require 'textui.style'
local textui_buffer = require 'textui.buffer'

local _G, textui, string, table, keys, math = _G, _M.textui, string, table, keys, math
local ipairs, error, type, setmetatable, select, tostring =
      ipairs, error, type, setmetatable, select, tostring
local string_rep = string.rep

local list = {}
local _ENV = list
if setfenv then setfenv(1, _ENV) end

style.list_header = { fore = '#5E5E5E', underline = true }

--- The default style to use for diplaying headers.
-- This is by default the `style.list_header` style. It's possible to override
-- this for a specific list by assigning another value to the instance itself.
header_style = style.list_header

--- The default styles to use for different columns. This can be specified
-- individually for each list as well. Values can either be explicit styles,
-- defined using @{_M.textui.style}, or functions which returns explicit styles.
-- In the latter case, the function will be invoked with the corresponding
-- item and column index.
--
-- The default styles contains styles for up to three columns, after which
-- the default style will be used.
column_styles = nil

-- I fought LDoc, but LDoc won. Define the field separately here to avoid it
-- being poorly documented as a table
column_styles =  {
  style.keyword,
  style.string,
  style.operator,
}

--- The maximum numbers of items to display in the list.
-- If the number of items are greater than this, this will be indicated visually
-- at the end of the list. It's possible to override this for a specific list
-- by assigning another value to the instance itself.
max_shown_items = 200

--- Whether searches are case insensitive or not.
-- It's possible to override this for a specific list by assigning another value
-- to the instance itself.
search_case_insensitive = true

--- List instance fields.
-- These can be set only for a list instance, and not globally for the module.
-- @section instance

--- Optional headers for the list.
-- If set, the headers must be a table with the same number of columns as
-- @{items}.
headers = nil

--- A table of items to display in the list.
-- Each table item can either be a table itself, in which case the list will
-- be muli column, or a string in which case the list be single column.
items = nil

--- The handler/callback to call when the user has selected an item.
-- The handler will be passed two parameters: the list itself, and the item
-- selected.
on_selection = nil

--- @section end

---
-- Creates a new list
-- @p title The list title
function new(title)
  if not title then error('no title specified', 2) end

  local _column_styles = {}
  setmetatable(_column_styles, {__index = list.column_styles})
  local l = {
    title = title,
    items = {},
    column_styles = _column_styles
  }
  setmetatable(l, {__index = list})
  l:_create_buffer()
  return l
end

---
-- Shows the list
function list:show()
  if not type(self) == 'table' then error('incorrect argument #1, needs list', 2) end

  self:_update_items_data()
  self.buffer.data = {}
  self.buffer:set_title(self.title)
  self.buffer:show()
end

---
-- Closes the list
function list:close()
  self.buffer:delete()
end

function list:is_own_buffer(buffer)
  return buffer == self.buffer.target
end

-- begin private section

-- Updates the state associated with items, i.e. matching state and
-- column widths
function list:_update_items_data()
  local lines = {}
  local column_widths = {}
  local max_line_length = 0
  for i, header in ipairs(self.headers or {}) do
    column_widths[1] = #tostring(header)
  end
  for i, item in ipairs(self.items) do
    if type(item) ~= 'table' then item = {item} end
    for j, field in ipairs(item) do
      column_widths[j] = math.max(column_widths[j] or 0, #tostring(field))
    end
    local text = table.concat(item, ' ')
    if self.search_case_insensitive then text = text:lower() end
    max_line_length = math.max(max_line_length, #text)
    lines[#lines + 1] = {
      text = text,
      index = i
    }
  end
  self._lines = lines
  self._column_widths = column_widths
  self._max_line_length = max_line_length
end

local function _fuzzy_search_pattern(search)
  local pattern = ''
  for i = 1, #search do
    pattern = pattern .. search:sub(i, i) .. '.-'
  end
  return pattern
end

-- matches search against line and returns a numeric score
-- if it maches, where lower is better
-- @param line the line to match
-- @param searches the search groups to match
-- @param fuzzy_score_penalty the score penalty to add for fuzzy matches
local function _match(line, searches, fuzzy_score_penalty)
  local score = 0

  for _, search in ipairs(searches) do
    local index = line:find(search, 1, true)
    if not index then
      local pattern = _fuzzy_search_pattern(search)
      index = line:find(pattern)
      if index then index = index + fuzzy_score_penalty end
    end

    if index then
      score = score + index
    else
      return nil
    end
  end
  return score
end

local function _search_groups(search)
  local groups = {}
  for part in search:gmatch('%S+') do groups[#groups + 1] = part end
  return groups
end

function list:_match_items()
  local data = self.buffer.data
  local search = data.search

  if not search or #search == 0 then
    data.matching_items = self.items
    return
  end

  if self.search_case_insensitive then search = search:lower() end

  data.cache = data.cache or {
    lines = {},
    items = {}
  }
  data.matching_items = data.cache.items[search] or {}
  if #data.matching_items > 0 then return end

  local search_groups = _search_groups(search)
  local lines = data.cache.lines[string.sub(search, 1, -2)] or self._lines
  local matching_lines = {}
  local matches = {}
  for i, line in ipairs(lines) do
    local score = _match(line.text, search_groups, self._max_line_length)
    if score then
      matches[#matches + 1] = { index = line.index, score = score }
      matching_lines[#matching_lines + 1] = line
    end
  end
  data.cache.lines[search] = matching_lines

  table.sort(matches, function(a ,b) return a.score < b.score end)
  local ordered_matches = {}
  for _, match in ipairs(matches) do
    ordered_matches[#ordered_matches + 1] = self.items[match.index]
  end
  data.cache.items[search] = ordered_matches
  data.matching_items = ordered_matches
end

function list:_column_style(item, column)
  local style = self.column_styles[column]
  if not style then return style.default end
  return type(style) == 'function' and style(item, column) or style
end

local function add_column_text(buffer, text, column_width, style)
  buffer:add_text(text, style)
  local padding = (column_width + 1) - #text
  buffer:add_text(string_rep(' ', padding))
end

function list:_refresh(buffer)
  local data = buffer.data
  self:_match_items()
  local matching_items = data.matching_items

  -- header
  buffer:add_text(self.title .. ' : ')
  buffer:add_text(#matching_items, style.number)
  buffer:add_text('/')
  buffer:add_text(#self.items, style.number)
  buffer:add_text(' items')
  if data.search and #data.search > 0 then
    buffer:add_text( ' matching ')
    buffer:add_text(data.search, style.comment)
  end
  buffer:add_text('\n\n')

  -- item listing
  local column_widths = self._column_widths
  local headers = self.headers
  if headers then
    for i, header in ipairs(self.headers or {}) do
      add_column_text(buffer, header, column_widths[i], self.header_style)
    end
    buffer:add_text('\n')
  end
  local item_listing_start = buffer.current_pos
  for i, item in ipairs(matching_items) do
    if i > self.max_shown_items then
      buffer:add_text(string.format("[...] (%d more items not shown)\n", #matching_items - self.max_shown_items), style.comment)
      break
    end
    local columns = type(item) == 'table' and item or { item }
    local line_start = buffer.current_pos
    for j, field in ipairs(columns) do
      add_column_text(buffer, tostring(field), column_widths[j], self:_column_style(columns, j))
    end
    buffer:add_text('\n')
    if self.on_selection then
      buffer:add_hotspot(line_start, buffer.current_pos, {self.on_selection, self, item})
    end
  end
  buffer:goto_pos(item_listing_start)
end

function list:_on_keypress(buffer, key, code, shift, ctl, alt, meta)
  if ctl or alt or meta or not key then return end

  local search = buffer.data.search or ''

  if #key == 1 and not string.match(key, '^%c$') then
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
  local buffer = textui_buffer.new(self.title)
  buffer.on_refresh = function(...) self:_refresh(...) end
  buffer.on_keypress = function(...) return self:_on_keypress(...) end
  self.buffer = buffer
  return buffer
end

return list
