--[[--
The hijack module provides the easiest, and most invasive, way of getting
Textredux functionality for Textadept. It's a one-stop setup in the way that
you don't really have to configure anything else to use the functionality of
Textredux  - the hijack module inserts itself anywhere it can and will
automatically integrate with your existing key bindings.

How to use
----------

After installing the Textredux module into your .textadept/modules directory,
simple add the following to your .textadept/init.lua file:

    require 'textredux.hijack'

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
@module _M.textredux.hijack
]]

_M.textredux = require 'textredux'

local fl = require 'textredux.hijack.filteredlist'
local fs = _M.textredux.fs

local ta = _M.textadept
local menu = ta.menu
local unpack = unpack or table.unpack

local function get_id(f)
    local id = ''
    if type(f) == 'function' then
      id = tostring(f)
    elseif type(f) == 'table' then
      for i = 1, #f do id = id..tostring(f[i]) end
    end
    return id
  end

local function patch_keys(replacements)
  local _keys = {}
  for k, v in pairs(keys) do
    _keys[k] = get_id(v)
  end
  for k, command_id in pairs(_keys) do
    local replacement = replacements[command_id]
    if replacement ~= nil then
      keys[k] = replacement
    end
  end
end

-- Table with unique identifiers for items to be replaced.
local replacements = {}
setmetatable(replacements, {__newindex = function(t, k, v)
  rawset(t, get_id(k), v)
end})

local io_snapopen = io.snapopen
local function snapopen_compat(utf8_paths, filter, exclude_FILTER, ...)
  if not utf8_paths or
     (type(utf8_paths) == 'table' and #utf8_paths ~= 1)
  then
    return io_snapopen(utf8_paths, filter, exclude_FILTER, ...)
  end
  local directory = type(utf8_paths) == 'table' and utf8_paths[1] or utf8_paths
  fs.snapopen(directory, filter, exclude_FILTER)
end

local io_open_file = io.open_file
local function open_file_compat(utf8_filenames)
  if utf8_filenames then return io_open_file(utf8_filenames) end
  fs.open_file()
end

local buffer_save_as = buffer.save_as
local save_as_compat
function save_as_compat(buffer, utf8_filename)
  if utf8_filename then return buffer_save_as(buffer, utf8_filename) end
  -- temporarily restore the original save_as, since fs.save_buffer_as uses it
  -- in its implementation
  _G.buffer.save_as = buffer_save_as
  local status, ret = pcall(fs.save_buffer_as)
  _G.buffer.save_as = save_as_compat
  if not status then events.emit(events.ERROR, ret) end
end

-- Hijack filteredlist for the below functions.
for _, target in ipairs({
  { gui, _RELEASE:find('Textadept 7') and 'set_theme' or 'select_theme' },
  { ta.mime_types, 'select_lexer' },
  { menu, 'select_command' },
  { io, 'open_recent_file' },
  { ta.bookmarks, 'goto_bookmark' },
}) do
  local func = target[1][target[2]]
  local wrap = fl.wrap(func)
  target[1][target[2]] = wrap
  replacements[func] = wrap
end

-- Hijack buffer list.
replacements[gui.switch_buffer] = _M.textredux.buffer_list.show
gui.switch_buffer = _M.textredux.buffer_list.show

-- Hijack snapopen.
replacements[io.snapopen] = snapopen_compat
io.snapopen = snapopen_compat

-- Hijack open file and save_as.
replacements[io.open_file] = open_file_compat
io.open_file = open_file_compat
replacements[buffer.save_as] = save_as_compat
events.connect(events.BUFFER_NEW, function() buffer.save_as = save_as_compat end)

-- Finalize by patching keys.
patch_keys(replacements)
