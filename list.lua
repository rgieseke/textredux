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
-- item and column index. The default styles contains styles for up to three
-- columns, after which the default style will be used.
column_styles = nil

-- I fought LDoc, but LDoc won. Define the field separately here to avoid it
-- being poorly documented as a table
column_styles =  {
  style.keyword,
  style.string,
  style.operator,
}

--- The maximum numbers of items to display in the list.
-- The default value is `nil`, in which case the list will show only as many
-- items as can be shown in the view. When there are more items than can be
-- shown. this will be indicated visually at the end of the list. The user can
-- then chose to show more interactively.
--
-- Please be aware that this is perhaps the biggest factor when it comes to
-- list performance, and that setting this to any large value will significantly
-- slow things down. It might be prudent to override this in case you know that
-- a specific type of list typically always contains less than, say 200 items or
-- so, but in the general case it's best left untouched.
--
-- It's possible to override this for a specific list by assigning another value
-- to the instance itself.
--
-- It's advised
max_shown_items = nil

--- Whether searches are case insensitive or not.
-- It's possible to override this for a specific list by assigning another value
-- to the instance itself. The default value is `true`.
search_case_insensitive = true

--- Whether fuzzy searching should be in addition to explicit matches.
-- It's possible to override this for a specific list by assigning another value
-- to the instance itself. The default value is `true`.
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
-- be muli column, or a string in which case the list be single column.
items = nil

--- The handler/callback to call when the user has selected an item.
-- The handler will be passed the following parameters:
--
-- - `list`: the list itself
-- - `item`: the item selected
on_selection = nil

--- The handler/callback to call when the user has typed in text which doesn't
-- match any item, and presses <enter>. The handler will be passed the following
-- parameters:
--
-- - `list`: the list itself
-- - `search`: the current search of the list
on_new_selection = nil

--- The underlying @{_M.textui.buffer} used by the list
buffer = nil

---
-- A table of key commands for the buffer.
-- This functions almost exactly the same as @{_M.textui.buffer.keys}. The one
-- difference is that for function values, the parameter passed will be a
-- reference to the list instead of a buffer reference.
keys = nil

--- Callback invoked whenever the list receives a keypress.
-- This functions almost exactly the sames as @{_M.textui.buffer.on_keypress}.
-- The one difference is that for function values, the first parameter passed
-- will be a reference to the list instead of a buffer reference.
--
-- Please note that by overriding this it's possible to block any key presses
-- from ever reaching the list itself.
-- @see keys
on_keypress = nil

--- A general purpose table that can be used for storing state associated
-- with the list. Just like @{_M.textui.buffer.data}, the `data` table is
-- special in the way that it will automatically be cleared whenever the user
-- closes the buffer associated with the list.
data = nil

--- @section end

--- Creates a new list.
-- @p title The list title
-- @return The new list instance
function new(title)
  if not title then error('no title specified', 2) end

  local _column_styles = {}
  setmetatable(_column_styles, { __index = column_styles })
  local l = {
    title = title,
    items = {},
    column_styles = _column_styles,
    data = {}
  }
  setmetatable(l, { __index = list })
  l:_create_buffer()
  return l
end

--- Shows the list.
function list:show()
  self:_update_items_data()
  self.buffer.data = {}
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

-- begin private section

-- Updates the state associated with items, e.g. column widths, maximum line
-- length and matching data.
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

local function fuzzy_search_pattern(search)
  local pattern = ''
  for i = 1, #search do
    pattern = pattern .. search:sub(i, i) .. '.-'
  end
  return pattern
end

--- Creates matches for the specified search
-- @param search_string The search string
-- @param fuzzy_search Whether fuzzy matches should be allowed
-- @param fuzzy_score_penalty The score penalty to add for fuzzy matches
-- @return A table of matcher functions, each taking a line as parameter and
-- returning a score (or nil for no match).
local function matchers_for_search(search_string, fuzzy_search, fuzzy_score_penalty)
  local groups = {}
  for part in search_string:gmatch('%S+') do groups[#groups + 1] = part end
  local matchers = {}
  for _, search in ipairs(groups) do
    local fuzzy_pattern = fuzzy_search and fuzzy_search_pattern(search)
    matchers[#matchers + 1] = function(line)
      local score = line:find(search, 1, true)
      if not score and fuzzy_search then
        local start_pos, end_pos = line:find(fuzzy_pattern)
        if start_pos then
          score = (end_pos - start_pos) + fuzzy_score_penalty
        end
      end
      return score and (score + #line) or nil
    end
  end
  return matchers
end

-- Applies search matchers on a line.
-- @param line The line to match
-- @param matchers The search matchers to apply
-- @return A numeric score if the line matches or nil otherwise. For scoring,
-- lower is better.
local function match(line, matchers)
  local score = 0

  for _, matcher in ipairs(matchers) do
    local matcher_score = matcher(line)
    if not matcher_score then return nil end
    score = score + matcher_score
  end
  return score
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

  local matchers = matchers_for_search(search, self.search_fuzzy, self._max_line_length)
  local lines = data.cache.lines[string.sub(search, 1, -2)] or self._lines
  local matching_lines = {}
  local matches = {}
  for i, line in ipairs(lines) do
    local score = match(line.text, matchers)
    if score then
      matches[#matches + 1] = { index = line.index, score = score }
      matching_lines[#matching_lines + 1] = line
    end
  end
  data.cache.lines[search] = matching_lines

  table.sort(matches, function(a ,b) return a.score < b.score end)
  local matching_items = {}
  for _, match in ipairs(matches) do
    matching_items[#matching_items + 1] = self.items[match.index]
  end
  data.cache.items[search] = matching_items
  data.matching_items = matching_items
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

function list:_refresh()
  local buffer = self.buffer
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
  local nr_columns = #column_widths

  -- headers
  local headers = self.headers
  if headers then
    for i, header in ipairs(self.headers or {}) do
      local pad_to = i == nr_columns and 0 or column_widths[i]
      add_column_text(buffer, header, pad_to, self.header_style)
    end
    buffer:add_text('\n')
  end

  -- items
  data.items_start_line = buffer:line_from_position(buffer.current_pos)
  local max_shown_items = self.max_shown_items or buffer.lines_on_screen - data.items_start_line - 1
  for i, item in ipairs(matching_items) do
    if i > max_shown_items then break end
    local columns = type(item) == 'table' and item or { item }
    local line_start = buffer.current_pos
    for j, field in ipairs(columns) do
      local pad_to = j == nr_columns and 0 or column_widths[j]
      add_column_text(buffer, tostring(field), pad_to, self:_column_style(columns, j))
    end
    buffer:add_text('\n')
    if self.on_selection then
      buffer:add_hotspot(line_start, buffer.current_pos, {self.on_selection, self, item})
    end
  end

  data.items_end_line = buffer:line_from_position(buffer.current_pos)
  if #matching_items > max_shown_items then
    local message = string.format(
      "[..] (%d more items not shown, select to show more)",
      #matching_items - max_shown_items
    )
    buffer:add_text(message, style.comment, { _show_more, self, max_shown_items } )
  end


  buffer:goto_line(data.items_start_line)
  buffer:home()
end

function list:_show_more(current_max)
  local buffer = self.buffer
  self.max_shown_items = current_max * 2
  local current_pos = buffer.current_pos
  buffer:refresh()
  buffer:goto_pos(current_pos)
end

function list:_on_keypress(buffer, key, code, shift, ctl, alt, meta)
  if self.on_keypress then
    local result = self.on_keypress(self, key, code, shift, ctl, alt, meta)
    if result then return result end
  end

  if ctl or alt or meta or not key then return end

  local search = buffer.data.search or ''

  if key == '\n' then
    if #search > 1 and self.on_new_selection then
      self.on_new_selection(self, search)
      return true
    end
  elseif #key == 1 and not string.match(key, '^%c$') then
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
  buffer.on_deleted = function() self.data = {} end
  self.buffer = buffer

  local key_wrapper = function(t, k, v)
    if type(v) == 'function' then
      buffer.keys[k] = function() v(self) end
    else
      buffer.keys[k] = v
    end
  end

  self.keys = setmetatable({}, { __index = buffer.keys, __newindex = key_wrapper })
  return buffer
end

return list
