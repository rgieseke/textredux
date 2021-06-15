-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
Textredux buffers wrap Textadept buffers and extend them with support for
custom styling, buffer specific key bindings and hotspot support.

## Usage

You create a new Textredux buffer by calling @{new}, passing the buffer title.
You specify an @{on_refresh} handler for the buffer, which is responsible for
actually inserting the content in the buffer, along with any custom styles and
hotspot handlers. Custom key bindings are specified using @{keys}. In the
@{on_refresh} handler, you add the actual text using any of the extended text
insertion functions (@{reduxbuffer:add_text}, @{reduxbuffer:append_text},
@{reduxbuffer:insert_text}). You invoke @{reduxbuffer:show} to show the buffer,
and respond to any interactions using the provided callbacks.

    local textredux = require('textredux')
    local reduxbuffer = textredux.core.buffer.new('Example buffer')
    reduxbuffer.on_refresh = function(buf)
      buf:add_text('Textredux!')
    end
    reduxbuffer:show()

If you need to test whether a Textadept buffer is used as a Textredux buffer
you can check for the `_textredux` field.

    events.connect(events.BUFFER_AFTER_SWITCH, function()
      local buffer = buffer
      if buffer._textredux then
        -- …
      end
    end)

## How it works

When you work with a Textredux buffer, it will nearly always seem just like an
ordinary [Textadept buffer](http://foicica.com/textadept/api/buffer.html)
(but with benefits, such as support for custom styling and easy callbacks,
etc.). But where a Textadept buffer is volatile, and might cease to exists at
any time (for example being closed by a user) a Textredux buffer is
persistent.

When we say that a Textredux buffer “wraps” a Textadept buffer, there's more
to it than just adding additional methods to the Textadept buffer API. A
Textredux buffer will always exist, but the corresponding Textadept buffer,
named `target` hereafter, may not. When the target buffer exists, a Textredux
buffer will expose all the functions and attributes of the Textadept buffer,
making it possible to use the Textredux buffer in just the same way as you would
a Textadept buffer (i.e. invoking any of the ordinary buffer methods, setting
attributes, etc.). Textredux takes care of creating the target buffer
automatically if needed whenever you invoke @{reduxbuffer:show}. When the target
buffer does not exist, for instance as the result of the user closing it, any
attempt to invoke any of the ordinary buffer methods will raise an error. You
can check explicitly whether the target buffer exists by using the
@{reduxbuffer:is_attached} function. However, this is not something you will
have to worry much about in practice, since you'll typically interact with the
buffer as part of a refresh, key press, etc., where the target buffer will
always exist.

In short, you don't have to worry about creating buffers, detecting whether the
buffer was closed, etc., as long as you remember to invoke @{reduxbuffer:show}
and perform your work within the callbacks.

@module textredux.core.buffer
]]

local M = {}

local textreduxbuffers = setmetatable({}, { __mode = 'k' })

local reduxstyle = require('textredux.core.style')
local reduxindicator = require('textredux.core.indicator')

local constants = _SCINTILLA.constants
local huge = math.huge

-- Style for selectable and clickable items.
reduxindicator.HOTSPOT = {style = constants.INDIC_HIDDEN}

local reduxbuffer = {}
local ce_active = nil

--- Instance fields. These can be set for a buffer instance, and not
-- globally for the module.
-- @section instance

--[[-- Whether the buffer should be marked as read only.
The default is true but can be changed on a buffer to buffer basis. Any call to
@{buffer:refresh} will automatically take care of setting the buffer to write
mode before invoking the @{on_refresh} handler, and will restore the
@{read_only} state afterwards.
]]
reduxbuffer.read_only = true

---
-- Callback invoked whenever the target buffer is deleted.
-- The callback has the following with the following parameters: `buffer`
reduxbuffer.on_deleted = nil

--[[-- Callback invoked whenever the buffer should refresh.
This should be set for each buffer. This callback is responsible for actually
inserting any content into the buffer. Before this callback
is invoked, any previous buffer content will be cleared.
The callback will be invoked with the buffer as the sole parameter.
@see refresh
]]
reduxbuffer.on_refresh = nil

--[[-- Callback invoked when a CHAR_ADDED event is fired.
Receives the char as an argument. This can be used to handle keypresses in a
buffer in read-only mode.
]]
reduxbuffer.on_char_added = nil

--[[-- A table of key commands for the buffer.
This is simply a `textadept.keys` mode, which is set whenever the Textredux
buffer is active. The format for specifying keys is the same as for
[textadept.keys](http://foicica.com/textadept/api/keys.html), thus the values
assigned can be either functions or tables.
]]
reduxbuffer.keys = nil

--[[--
A general purpose table that can be used for storing state associated with the
buffer. The `data` table is will automatically be cleared whenever the target
buffer is closed.
]]
reduxbuffer.data = nil

--[[--- The target buffer, if any.
This holds a reference to the target buffer, when present.
]]
reduxbuffer.target = nil

--- The buffer open when a Textredux buffer was shown.
-- Stored to be able to go back to after closing the Textredux buffer.
reduxbuffer.origin_buffer = nil

---
-- @section end

-- Look up values in the reduxbuffer table or the built-in buffer.
local function __index(t, k)
  local value = rawget(t, k)
  if value then return value end
  if rawget(reduxbuffer, k) then return rawget(reduxbuffer, k) end
  local target = rawget(t, 'target')
  if target then
    value = target[k]
    if type(value) == 'function' then
      return function(_, ...)
        return value(target, ...)
      end
    else
      return value
    end
  end
end

-- Set values in the built-in target buffer or the Textredux buffer instance.
local function __newindex(t, k, v)
  if rawget(t, target) and rawget(t, target, k) then
    rawset(t.target, k, v)
  else
    rawset(t, k, v)
  end
end

---
-- Creates and returns a new Textredux buffer. The buffer will not be attached
-- upon the return.
-- @param title The title of the buffer. This will be displayed as the buffer's
-- title in Textadept's top bar.
function M.new(title)
  local buf = {
    title = title,
    data = {},
    keys = {},
    hotspots = {}
  }
  textreduxbuffers[buf] = true
  buf.keys_mode = 'textredux '..tostring(buf)
  keys[buf.keys_mode] = {}
  setmetatable(keys[buf.keys_mode], {__index = keys})
  setmetatable(buf.keys, {__newindex = function(t, k, v)
    -- Add to keys mode.
    rawset(keys[buf.keys_mode], k, v)
  end})
  buf.keys.esc = function() buf:close() end
  buf.keys['\n'] = function() buf:_on_user_select(buf.current_pos) end
  return setmetatable(buf, {__index = __index, __newindex = __newindex})
end

-- Activate Textredux keys mode on buffer or view switch and file open.
-- Otherwise activate Textadept's  default keys  mode.
local function set_keys_mode()
  if ce_active then
    keys.mode = ce_active.keys_mode
  elseif buffer._textredux then
    keys.mode = buffer._textredux.keys_mode
  else
    keys.mode = M.DEFAULT_MODE
  end
end
events.connect(events.BUFFER_AFTER_SWITCH, set_keys_mode)
events.connect(events.VIEW_AFTER_SWITCH, set_keys_mode)
events.connect(events.FILE_OPENED, set_keys_mode)

-- Handle CHAR_ADDED events. Key codes are translated to strings before they
-- are passed to the Textredux `on_char_added` handler.
events.connect(events.CHAR_ADDED, function(code)
  local _textredux = buffer._textredux
  if not _textredux then return end
  if _textredux.on_char_added then
    local char = code < 256 and (not CURSES or (code ~= 7 and code ~= 13)) and
        string.char(code) or keys.KEYSYMS[code]

    if char ~= nil then
      _textredux.on_char_added(char)
    end
  end
end)

--[[-- Shows the buffer.
If the target buffer doesn't exist, due to it either not having been created
yet or having been deleted, it is automatically created. Upon the return, the
buffer is showing and set as the global buffer.
]]
function reduxbuffer:show()
  local origin_buffer = buffer
  if not self:is_attached() then self:_create_target() end
  if not self:is_showing() then view:goto_buffer(_BUFFERS[self.target]) end
  if origin_buffer ~= buffer then
    self.origin_buffer = origin_buffer
    self.origin_key_mode = keys.mode
  end
  self:refresh()
  keys.mode = self.keys_mode
end

function reduxbuffer:attach_to_command_entry()
  local target = ui.command_entry
  target._textredux = self
  target:set_lexer('text')
  target.eol_mode = constants.EOL_LF
  target:set_save_point()
  target.undo_collection = false
  self.target = target
  self.is_command_entry = true
  target:clear_all()
  target:focus()
  ce_active = self
  set_keys_mode()
  self:refresh()
end

--- Closes the buffer.
function reduxbuffer:close()
  if self.is_command_entry then
    ui.command_entry._textredux = nil
    ui.command_entry.read_only = false
    ui.command_entry:focus()
    ce_active = nil
    set_keys_mode()
  else
    if not self:is_active() then view:goto_buffer(_BUFFERS[self.target]) end
    self.target:close()
  end
end

--[[-- Performs an update of the buffer contents.
You invoke this with a callback that will do the actual update. This function
takes care of ensuring that the target is writable, and handles setting the
save point, etc.
@param callback The callback to invoke to perform the update. The callback
will receive the buffer instance as its sole parameter.
]]
function reduxbuffer:update(callback)
  if not (self:is_attached() or self.is_command_entry) then error("Can't refresh: not attached") end
  self.target.read_only = false
  callback(self)
  self.target.read_only = self.read_only
  self:set_save_point()
end

-- Block the default attempt to restore the previous caret position
-- when buffer contents are replaced. When the blocker is hit, it removes
-- itself so that future, non-Textredux events can still trigger the default behavior.
local function block_event()
  events.disconnect(events.BUFFER_AFTER_REPLACE_TEXT, block_event)
  return true
end

--[[-- Refreshes the buffer.
A refresh works by ensuring that it's possible to write to the buffer and
invoking the @{on_refresh} handler. After the refresh is complete, the
@{read_only} state is reset to whatever it was before the refresh, and a save
point is set.

Please note that a refresh will clear all content, along with hotspots, etc.
If you want to perform smaller updates please use the @{buffer:update} function
instead.
]]
function reduxbuffer:refresh()
  self:update(function()
    self.hotspots = {}
    self:clear_all()
    if self.on_refresh then
      events.connect(events.BUFFER_AFTER_REPLACE_TEXT, block_event, 1)
      self:on_refresh()
    end
  end)
end

--- Updates the title of the buffer.
function reduxbuffer:set_title(title)
  self.title = title
  if self:is_attached() then
    self.target._type = title
  end
end

---
-- Checks whether a target buffer currently exists.
-- @return true if the target buffer exists and false otherwise
function reduxbuffer:is_attached()
  return self.target ~= nil
end

---
-- Checks whether the buffer is currently showing in any view.
-- @return true if the buffer is showing and false otherwise
function reduxbuffer:is_showing()
  if not self.target then return false end
  for _, view in ipairs(_VIEWS) do
    if view.buffer == self.target then return true end
  end
  return false
end

---
-- Checks whether the buffer is currently active, i.e. the current buffer.
-- @return true if the buffer is active and false otherwise
function reduxbuffer:is_active()
  return self.target and self.target == buffer
end

--[[-- Adds a hotspot for the given text range.
Hotspots allows you to specify  what happens when the user selects
a text range. Besides using this function directly, it's also possible and
in many cases more convenient to add a hotspot when using any of the text
insertion functions (@{buffer:add_text}, @{buffer:append_text},
@{buffer:insert_text}). Note that the range given is interpreted as being
half closed, i.e. `[start_pos, end_pos)`.

Note that all hotspots are cleared as part of a refresh.
@param start_pos The start position
@param end_pos The end position. The end position itself is not part of the
hotspot.
@param command The command to execute. Similarily to @{keys}, the command can
be either a function or a table. When the command is a function, it will be
passed the buffer instance as a parameter.
]]
function reduxbuffer:add_hotspot(start_pos, end_pos, command)
  local hotspots = self.hotspots
  local target = self.target
  local start_line = target:line_from_position(start_pos)
  local end_line = target:line_from_position(end_pos - 1)

  for i = start_line, end_line do
    local start_p = i == start_line and start_pos or 0
    local end_p = i == end_line and end_pos or huge
    local hotspot = { start_pos = start_p, end_pos = end_p, command = command }
    local current_spots = hotspots[i] or {}
    current_spots[#current_spots + 1] = hotspot
    hotspots[i] = current_spots
  end
  local length = end_pos - start_pos
  -- Temporarily replace the global Textadept `buffer` variable with the
  -- buffer we're working on.  This is so that when attached to the command
  -- entry buffer (which `_G.buffer` doesn't point to), the styling etc.
  -- functions, which assume they're working on the current buffer, still
  -- work.
  local saved_buf = buffer
  _G.buffer = self.target
  reduxindicator.HOTSPOT:apply(start_pos, length)
  _G.buffer = saved_buf
end

-- Add styling and hotspot support to buffer text insertion functions.

--[[-- Override for
[buffer:add_text](http://foicica.com/textadept/api/buffer.html#add_text)
which accepts optional style, command and indicator parameters.
@param text The text to add.
@param style The style to use for the text, as defined using
@{textredux.core.style}.
@param command The command to run if the user "selects" this text. See
@{buffer:add_hotspot} for more information.
@param indicator Optional @{textredux.core.indicator} to use for the added
text.
]]
function reduxbuffer:add_text(text, style, command, indicator)
  text = tostring(text)
  local insert_pos = self.target.current_pos
  -- Temporarily replace the global Textadept `buffer` variable with the
  -- buffer we're working on.  This is so that when attached to the command
  -- entry buffer (which `_G.buffer` doesn't point to), the styling etc.
  -- functions, which assume they're working on the current buffer, still
  -- work.
  local saved_buf = buffer
  _G.buffer = self.target
  self.target:add_text(text)
  if not style then style = reduxstyle.default end
  style:apply(insert_pos, #text)
  if command then self:add_hotspot(insert_pos, insert_pos + #text, command) end
  if indicator then indicator:apply(insert_pos, #text) end
  _G.buffer = saved_buf
end

--[[-- Override for
[buffer:append_text](http://foicica.com/textadept/api/buffer.html#append_text)
which accepts optional style, command and indicator parameters.
@param text The text to append.
@param style The style to use for the text, as defined using
@{textredux.core.style}.
@param command The command to run if the user "selects" this text. See
@{buffer:add_hotspot} for more information.
@param indicator Optional @{textredux.core.indicator} to use for the appended
text.
]]
function reduxbuffer:append_text(text, style, command, indicator)
  local insert_pos = self.target.length
  text = tostring(text)
  self.target:append_text(text)
  -- Temporarily replace the global Textadept `buffer` variable with the
  -- buffer we're working on.  This is so that when attached to the command
  -- entry buffer (which `_G.buffer` doesn't point to), the styling etc.
  -- functions, which assume they're working on the current buffer, still
  -- work.
  local saved_buf = buffer
  _G.buffer = self.target
  if not style then style = reduxstyle.default end
  style:apply(insert_pos, #text)
  if command then self:add_hotspot(insert_pos, insert_pos + #text, command) end
  if indicator then indicator:apply(insert_pos, #text) end
  _G.buffer = saved_buf
end

--[[-- Override for
[buffer:insert_text](http://foicica.com/textadept/api/buffer.html#insert_text)
which accepts optional style, command and indicator parameters.
@param pos The position to insert text at or `-1` for the current position.
@param text The text to insert.
@param style The style to use for the text, as defined using
@{textredux.core.style}.
@param command The command to run if the user "selects" this text. See
@{buffer:add_hotspot} for more information.
@param indicator Optional @{textredux.core.indicator} to use for the inserted
text.
]]
function reduxbuffer:insert_text(pos, text, style, command, indicator)
  text = tostring(text)
  self.target:insert_text(pos, text)
  -- Temporarily replace the global Textadept `buffer` variable with the
  -- buffer we're working on.  This is so that when attached to the command
  -- entry buffer (which `_G.buffer` doesn't point to), the styling etc.
  -- functions, which assume they're working on the current buffer, still
  -- work.
  local saved_buf = buffer
  _G.buffer = self.target
  if not style then style = reduxstyle.default end
  style:apply(insert_pos, #text)
  if command then self:add_hotspot(pos, pos + #text, command) end
  if indicator then indicator:apply(pos, #text) end
  _G.buffer = saved_buf
end

-- Begin private code.

-- Create a new buffer and store a reference in the `target` attribute.
function reduxbuffer:_create_target()
  local target = buffer.new()
  target._textredux = self
  target:set_lexer('text')
  target.eol_mode = constants.EOL_LF
  target.wrap_mode = target.WRAP_NONE
  target.margin_width_n[2] = not CURSES and target.margin_width_n[1] + 4 or 1
  target.margin_width_n[1] = 0
  target:set_save_point()
  target.undo_collection = false
  self.target = target
  self:set_title(self.title)
  reduxstyle.activate_styles()
end

-- Invoke command.
local function invoke_command(command, buffer)
  local f = command
  local args = { buffer, shift, ctl, alt, meta }
  if type(command) == 'table' then
    f = command[1]
    args = { table.unpack(command, 2) }
  end
  xpcall(f, function(e) events.emit(events.ERROR, e) end, table.unpack(args))
end

-- Return to the buffer in which the Textredux buffer was opened.
function reduxbuffer:_restore_origin_buffer()
  local origin_buffer = self.origin_buffer
  if origin_buffer then
    local buf_index = _BUFFERS[origin_buffer]
    if buf_index and originbuffer ~= buffer then
      view:goto_buffer(buf_index, false)
      keys.mode = self.origin_key_mode
    end
  end
end

-- Event hooks.

-- Called on pressing enter or clicking an item.
function reduxbuffer:_on_user_select(position)
  local target = self.target
  local cur_line = target:line_from_position(position)
  local spots = self.hotspots[cur_line]
  if not spots then return end
  for _, spot in ipairs(spots) do
    if position >= spot.start_pos and position < spot.end_pos then
      invoke_command(spot.command, self)
      return true
    end
  end
end

-- Called when closing a buffer.
local function _on_buffer_deleted()
  for buf, _ in pairs(textreduxbuffers) do
    if buf:is_attached() and not _BUFFERS[buf.target] then
      buf.target = nil
      buf.data = {}
      if buf.on_deleted then buf:on_deleted() end
      break
    end
  end
end

local function _on_buffer_after_switch()
  local reduxbuffer = buffer._textredux
  if reduxbuffer then
    reduxbuffer:refresh()
  end
end

-- We close all Textredux buffer upon quit - they won't restore properly anyway
-- and it's annoying to have empty non-functioning buffers upon start.
local function _on_quit()
  for _, buffer in ipairs(_BUFFERS) do
    if buffer._textredux then
      view:goto_buffer(_BUFFERS[buffer])
      buffer:close()
    end
  end
end

-- Mouse support.
local function _on_indicator_release(position)
  local tr_buf = buffer._textredux
  if not tr_buf then return end

  local cur_view = view
  if tr_buf:_on_user_select(position, shift, ctrl, alt, meta) then
    -- If the view's buffer was switched as a result of the select, the new
    -- buffer will get a weird selection. Work around that
    -- somewhat by setting the buffer's position to the position it will get
    -- upon the return. This will change a position already set in the callback.
    if _VIEWS[cur_view] and cur_view.buffer ~= tr_buf.target then
      local focused_view = view
      if cur_view ~= focused_view then
        ui.goto_view(_VIEWS[cur_view], false)
      end
      buffer:goto_pos(position)
      if view ~= focused_view then
        ui.goto_view(_VIEWS[focused_view], false)
      end
    end
    return true
  end
end

events.connect(events.BUFFER_DELETED, _on_buffer_deleted)
events.connect(events.BUFFER_AFTER_SWITCH, _on_buffer_after_switch)
events.connect(events.INDICATOR_RELEASE, _on_indicator_release)
events.connect(events.QUIT, _on_quit, 1)
events.connect(events.RESET_BEFORE, _on_quit)
return M
