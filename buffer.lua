--[[--
The buffer class wraps a Textadept buffer, and extends it with support for
custom styling, buffer specific key bindings and hotspot support. It takes
care of the details needed for making a text based interface work, such as
mapping Textadept events to the correct buffers, working with the @{_M.textui.style}
module to ensure that styling works, etc.

How it works
------------

When you work with a TextUI buffer, it will nearly always seem just like an ordinary
[Textadept buffer](http://caladbolg.net/luadoc/textadept/modules/buffer.html)
(but with benefits, such as support for custom styling and easy callbacks, etc.).
But where an Textadept buffer is volatile, and might cease to exists at any
time (due to it being closed by a user for example) a TextUI buffer is persistent.

When we say that a TextUI buffer "wraps" an Textadept buffer, there's more to it
than just adding additional methods to the Textadept buffer class. A TextUI
buffer will always exist, but the corresponding Textadept buffer, named `target`
hereafter, may not. When the target buffer exists, a TextUI buffer will
expose all the functions and attributes of the Textadept buffer, making it
possible to use the TextUI buffer in just the same way as you would a Textadept
buffer (i.e. invoking any of the ordinary buffer methods, setting attributes,
etc.). The TextUI buffer takes care of creating the target buffer automatically
if needed whenever you invoke @{buffer:show}. When the target buffer does not
exist, for instance as the result of the user closing it, any attempt to invoke
any of the ordinary buffer methods will raise an error. You can check explicitly
whether the target exists by using the @{buffer:is_attached} function. This is
not however something you will have to worry much about in practice, since you'll
typically interact with the buffer as part of a refresh, key press, etc., where
the target buffer will always exist.

In short, you don't have to worry about creating buffers, detecting whether the
buffer was closed, etc., as long as you remember to invoke @{buffer:show} and
perform your work within the callbacks.

How to use
----------

You create a new TextUI buffer by calling @{new}, passing the buffer
title. You specify an @{on_refresh} handler for the buffer, which is responsible
for actually inserting the content in the buffer, along with any custom styles
and hotspot handlers. You specify any custom key bindings using either @{keys}
or @{on_keypress}, and/or hook any other handlers of interest. In the
@{on_refresh} handler, you add the actual text using any of the extended
text insertion functions (@{buffer:add_text}, @{buffer:append_text},
@{buffer:insert_text} or possibly @{buffer:newline}). You invoke
@{buffer:show} to show the buffer, and respond to any interactions using the
provided callbacks.

Please see the examples for more hands on instructions.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textui.buffer
]]

local key = require('textui.key')
local tui_style = require('textui.style')
local tui_indicator = require('textui.indicator')

local _G = _G
local error, setmetatable, ipairs, pairs, tostring, error, rawget, rawset, type, xpcall, select =
      error, setmetatable, ipairs, pairs, tostring, error, rawget, rawset, type, xpcall, select
local new_buffer, events, table = new_buffer, events, table
local constants = _SCINTILLA.constants
local huge = math.huge
local band = bit32.band

local buffer = {}
local _ENV = buffer
if setfenv then setfenv(1, _ENV) end

local default_style = tui_style.default
local hotspot_indicator = { style = constants.INDIC_HIDDEN }
local __newindex, __index
local tui_buffers = setmetatable({}, { __mode = 'k' })
local origin_buffers  = setmetatable({}, { __mode = 'kv' })

--[[- Whether the buffer should be marked as read only.
The default is true but can be changed on a buffer to buffer basis. Any call to
@{buffer:refresh} will automatically take care of setting the buffer to write
mode before invoking the @{on_refresh} handler, and will restore the @{read_only}
state afterwards.
]]
read_only = true

--- Instance fields. These can be set only for an buffer instance, and not
-- globally for the module.
-- @section instance

---
-- Callback invoked whenever the target buffer is deleted.
-- The callback has the following with the following parameters: `buffer`
on_deleted = nil

--[[- Callback invoked whenever the buffer should refresh.
This should set for each buffer. It is this callback that is responsible
for actually inserting any content into the buffer. Before this callback
is invoked, any previous buffer content will be cleared.
The callback will be invoked with the buffer as the sole parameter.
@see buffer:refresh
]]
on_refresh = nil

--[[- Callback invoked whenever the buffer receives a keypress.
Please note that if there is any key command defined in @{keys} matching
the keypress, that key command will be invoked and this callback will never
be called. The callback will receive the following parameters:

- `buffer`: The buffer instance.
- `key`: The "translated key" (same format as for @{keys}).
- `code`: The key code.
- `shift`: True if the Shift key was held down.
- `ctrl`: True if the Control/Command key was held down.
- `alt`: True if the Alt/option key was held down.
- `meta`: True if the Control key on Mac OSX was held down.

It's similar to the standard Textadept KEYPRESS event (which you can read more
about [here](http://caladbolg.net/luadoc/textadept/modules/events.html)).
The return value determines whether the key press should be propagated, just
the same as for the standard Textadept event.
@see keys
]]
on_keypress = nil

--[[- A table of key commands for the buffer.
This is similar to `_M.textadept.keys` works, but allows you to specify key
commands specifically for one buffer. The format for specifying keys
is the same as for
[_M.textadept.keys](http://caladbolg.net/luadoc/textadept/modules/keys.html),
and the values assigned can also be either functions or tables.
There are differences compared to `_M.textadept.keys` however:

- It's not possible to specify language specific key bindings. This is
obviously not applicable for a textui buffer.
- It's not possible to specify keychain sequences.
- For function values, the buffer instance is passed as the first argument.
- For table values, buffer or view references will not be magically fixed.
  This means that you should not use either of the above in a table command,
  unless you enjoy the occasional segfault.

In short, only explicit simple mappings are supported. Defining a key command
for a certain key means that key presses are never propagated any further for
that particular key. Key commands take preference over any @{on_keypress}
callback, so any such callback will never be called if a key command matches.
@see on_keypress
]]
keys = nil

---
-- A general purpose table that can be used for storing state associated
-- with the buffer. The `data` table is special in the way that it will
-- automatically be cleared whenever the user closes the buffer.
data = nil

--- The target buffer, if any.
-- This holds a reference to the target buffer, when present.
target = nil

---
-- @section end

---
-- Creates and returns a new textui buffer. The buffer will not be attached
-- upon the return.
-- @param title The title of the buffer. This will be displayed as the buffer's
-- title in the Textadept top bar.
function new(title)
  local buf = {
    title = title,
    data = {},
    keys = {},
    hotspots = {},
    fields = {
      target = 1,
      on_keypress = 1,
      on_refresh = 1,
      on_deleted = 1,
      read_only = 1,
    },
  }
  setmetatable(buf, {__index = __index, __newindex = __newindex})
  tui_buffers[buf] = true
  return buf
end

--- Shows the buffer.
-- If the target buffer doesn't exist, due to it either not having been created
-- yet or it having been deleted, it is automatically created. Upon the return,
-- the buffer is showing and set as the global buffer.
function buffer:show()
  local origin_buffer = _G.buffer
  if not self:is_attached() then self:_create_target() end
  _G.view:goto_buffer(_G._BUFFERS[self.target], false)
  if origin_buffer ~= _G.buffer then
    origin_buffers[self] = origin_buffer
  end
end

--- Closes the buffer.
function buffer:close()
  if self:is_attached() then
    self:show()
    self.target:delete()
  end
end

--[[- Performs an update of the buffer contents.
You invoke this with a callback that will do the actual update. This function
takes care of ensuring that the target is writable, and handles setting the
save point, etc.
@param callback The callback to invoke to perform the update. The callback
will receive the buffer instance as its sole parameter.
]]
function buffer:update(callback)
  if not self:is_attached() then error("Can't refresh: not attached", 2) end
  self.target.read_only = false
  callback(self)
  self.target.read_only = self.read_only
  self:set_save_point()
end

--[[- Refreshes the buffer.
A refresh works by ensuring that it's possible to write to the buffer and
invoking the @{on_refresh} handler. After the refresh is complete, the
@{read_only} state is reset to whatever it was before the refresh, and a save
point is set.

Please note that a refresh will clear all content, along with hotspots, etc.
If you want to perform smaller updates please use the @{buffer:update} function
instead.
]]
function buffer:refresh()
  self:update(function()
    self.hotspots = {}
    self:clear_all()
    self:_call_hook('on_refresh')
  end)
end

---
-- Updates the title of the buffer.
--
function buffer:set_title(title)
  self.title = title
  if self:is_attached() then
    -- there's currently an issue with how TA handles the titlebar update -
    -- it can't handle trailing slashes so work around that for now
    if title:match('[/\\]$') then title = title .. '\0' end
    self.target._type = title
  end
end

---
-- Checks whether a target buffer currently exists.
-- @return true if the target buffer exists and false otherwise
function buffer:is_attached()
  return self.target ~= nil
end

---
-- Checks whether the buffer is currently showing in any view.
-- @return true if the buffer is showing and false otherwise
function buffer:is_showing()
  if not self.target then return false end
  for i, view in ipairs(_G._VIEWS) do
    if view.buffer == self.target then return true end
  end
  return false
end

---
-- Checks whether the buffer is currently active, i.e. the current buffer.
-- @return true if the buffer is active and false otherwise
function buffer:is_active()
  return self.target and self.target == _G.buffer
end

--[[- Adds a hotspot for the given text range.
Hotspots allows you to specify the behaviour for when the user selects
certain text. Besides using this function directly, it's also possible and
in many cases more convinient to add an hotspot when using any of the text
insertion functions (@{buffer:add_text}, @{buffer:append_text},
@{buffer:insert_text}). Note that the range given is interpreted as being
half closed, i.e. `[start_pos, end_pos)`.

*NB*: Please note that all hotspots are cleared as part of a refresh.
@param start_pos The start position
@param end_pos The end position. The end position itself is not part of the
hotspot.
@param command The command to execute. Similarily to @{keys}, command can be
either a function or a table. When the command is a function, it will be passed
the following parameters:

- `buffer`: The buffer instance
- `shift`: True if the Shift key was held down.
- `ctrl`: True if the Control/Command key was held down.
- `alt`: True if the Alt/option key was held down.
- `meta`: True if the Control key on Mac OSX was held down.
]]
function buffer:add_hotspot(start_pos, end_pos, command)
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
  length = end_pos - start_pos
  tui_indicator.apply(hotspot_indicator, start_pos, length)
end

-- add styling and hotspot support to buffer text insertion functions

--[[- Override for
[buffer:add_text](http://caladbolg.net/luadoc/textadept/modules/buffer.html#buffer.add_text)
which accepts optional style, command and indicator parameters.
@param text The text to add.
@param style The style to use for the text, as defined using @{_M.textui.style}.
@param command The command to run if the user "selects" this text. See
@{buffer:add_hotspot} for more information.
@param indicator Optional @{_M.textui.indicator} to use for the added text.
]]
function buffer:add_text(text, style, command, indicator)
  text = tostring(text)
  local insert_pos = self.target.current_pos
  self.target:add_text(text)
  self:_set_style(insert_pos, #text, style)
  if command then self:add_hotspot(insert_pos, insert_pos + #text, command) end
  if indicator then tui_indicator.apply(indicator, insert_pos, #text) end
end

--[[- Override for
[buffer:append_text](http://caladbolg.net/luadoc/textadept/modules/buffer.html#buffer.append_text)
which accepts optional style, command and indicator parameters.
@param text The text to append.
@param style The style to use for the text, as defined using @{_M.textui.style}.
@param command The command to run if the user "selects" this text. See
@{buffer:add_hotspot} for more information.
@param indicator Optional @{_M.textui.indicator} to use for the appended text.
]]
function buffer:append_text(text, style, command, indicator)
  local insert_pos = self.target.length
  text = tostring(text)
  self.target:append_text(text)
  self:_set_style(insert_pos, #text, style)
  if command then self:add_hotspot(insert_pos, insert_pos + #text, command) end
  if indicator then tui_indicator.apply(indicator, insert_pos, #text) end
end

--[[- Override for
[buffer:insert_text](http://caladbolg.net/luadoc/textadept/modules/buffer.html#buffer.insert_text)
which accepts optional style, command and indicator parameters.
@param pos The position to insert text at or `-1` for the current position.
@param text The text to insert.
@param style The style to use for the text, as defined using @{_M.textui.style}.
@param command The command to run if the user "selects" this text. See
@{buffer:add_hotspot} for more information.
@param indicator Optional @{_M.textui.indicator} to use for the inserted text.
]]
function buffer:insert_text(pos, text, style, command, indicator)
  text = tostring(text)
  self.target:insert_text(pos, text)
  self:_set_style(pos, #text, style)
  if command then self:add_hotspot(pos, pos + #text, command) end
  if indicator then tui_indicator.apply(indicator, pos, #text) end
end

--[[-
Override for
[buffer:new_line](http://caladbolg.net/luadoc/textadept/modules/buffer.html#buffer.new_line).
A TextUI buffer will always have eol mode set to LF, so it's also possible,
and arguably easier, to just insert a newline using the `\n` escape via any
of the other text insertion functions.
]]
function buffer:newline()
  self:add_text('\n', tui_style.whitespace)
end

-- begin private code

function buffer:_set_style(pos, length, style)
  tui_style.apply(style or default_style, self.target, pos, length)
end

function buffer:_create_target()
  local target = new_buffer()
  target._textui = self
  target:set_lexer_language(constants.SCLEX_CONTAINER)
  target.eol_mode = constants.SC_EOL_LF
  target:set_save_point()
  target.undo_collection = false
  self.target = target
  self:set_title(self.title)
end

function buffer:_call_hook(hook, ...)
  local callback = self[hook]
  if not callback then return end
  return callback(self, ...)
end

local function emit_error(error)
  events.emit(events.ERROR, error)
end

function __index(tui_buf, k)
  local value = rawget(buffer, k)
  if value then return value end
  if tui_buf.fields[k] then return nil end
  local target = rawget(tui_buf, 'target')
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

function __newindex(tui_buf, k, v)
  if tui_buf.fields[k] then
    rawset(tui_buf, k, v)
  elseif tui_buf.target then
    tui_buf.target[k] = v
  else
    error("'=': Unknown field '" .. k .. "', perhaps invoke :show() first?", 2)
  end
end

local function invoke_command(command, buffer, shift, ctl, alt, meta)
  local f = command
  local args = { buffer, shift, ctl, alt, meta }
  if type(command) == 'table' then
    f = command[1]
    args = { table.unpack(command, 2) }
  end
  xpcall(f, emit_error, table.unpack(args))
end

function buffer:_restore_origin_buffer()
  local origin_buffer = origin_buffers[self]
  if origin_buffer then
    local buf_index = _G._BUFFERS[origin_buffer]
    if buf_index and origin_buffer ~= _G.buffer then
      _G.view:goto_buffer(buf_index, false)
    end
  end
end

-- event hooks
function buffer:_on_target_deleted()
  self.target = nil
  self.data = {}
  self:_restore_origin_buffer()
  self:_call_hook('on_deleted')
end

function buffer:_on_user_select(position, shift, ctrl, alt, meta)
  local target = self.target
  local cur_line = target:line_from_position(position)
  local spots = self.hotspots[cur_line]
  if not spots then return end
  for _, spot in ipairs(spots) do
    if position >= spot.start_pos and position < spot.end_pos then
      invoke_command(spot.command, self, shift, ctrl, alt, meta)
      return true
    end
  end
end

local function _on_buffer_deleted()
  local ta_buffers = _G._BUFFERS
  for tui_buf, _ in pairs(tui_buffers) do
    if tui_buf:is_attached() and not ta_buffers[tui_buf.target] then
      tui_buf:_on_target_deleted()
      break
    end
  end
end

local function _on_buffer_after_switch()
  local tui_buf = _G.buffer._textui
  if tui_buf then
    tui_style.define_styles()
    tui_indicator.define_indicators()
    tui_buf:refresh()
  end
end

local function _on_new_view()
  local tui_buf = _G.buffer._textui
  if tui_buf then
    local tmp_buf = new_buffer()
    tmp_buf:delete()
    tui_buf:show()
  end
end

-- we close all textui buffer upon quit - they won't restore properly anyway
-- and it's annoying to have empty non-functioning buffers upon start
local function _on_quit()
  local buffers = {}
  for tui_buf,_ in pairs(tui_buffers) do buffers[#buffers + 1] = tui_buf end
  for _, tui_buf in ipairs(buffers) do
    tui_buf:close()
  end
end

local function _on_keypress(code, shift, ctl, alt, meta)
  local tui_buf = _G.buffer._textui
  if not tui_buf then return end
  local key = key.translate(code, shift, ctl, alt, meta)

  if key and key:match('\n') and
     tui_buf:_on_user_select(tui_buf.current_pos, shift, ctl, alt, meta) then
    return true
  end

  local command = tui_buf.keys[key]
  if command then
    invoke_command(command, tui_buf, shift, ctl, alt, meta)
    return true
  end
  return tui_buf:_call_hook('on_keypress', key, code, shift, ctl, alt, meta)
end

--[[ Mouse support.. The stack has the following issues:

- Modifiers are not reported correctly (ctrl pressed reports as ctrl+alt)
- Doing buffer switches in the action results in the new buffer recieving button
up and setting a selection.
- Scintilla docs says indicator release event gets modifiers - we do not.
]]
local indicator_modifiers

local function _on_indicator_click(position, modifiers)
  if not _G.buffer._textui then return end
  indicator_modifiers = modifiers
end

local function _on_indicator_release(position, modifiers)
  local tui_buf = _G.buffer._textui
  if not tui_buf then return end

  modifiers = modifiers or indicator_modifiers or 0
  local shift = band(constants.SCMOD_SHIFT, modifiers) ~= 0
  local ctrl = band(constants.SCMOD_CTRL, modifiers) ~= 0
  local alt = band(constants.SCMOD_ALT, modifiers) ~= 0
  local meta = band(constants.SCMOD_META, modifiers) ~= 0

  if tui_buf:_on_user_select(position, shift, ctrl, alt, meta) then
    return true
  end
end

events.connect(events.BUFFER_DELETED, _on_buffer_deleted)
events.connect(events.BUFFER_AFTER_SWITCH, _on_buffer_after_switch)
events.connect(events.KEYPRESS, _on_keypress, 1)
events.connect(events.INDICATOR_CLICK, _on_indicator_click)
events.connect(events.INDICATOR_RELEASE, _on_indicator_release)
events.connect(events.VIEW_NEW, _on_new_view)
events.connect(events.QUIT, _on_quit, 1)

return buffer
