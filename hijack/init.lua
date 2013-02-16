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

local function get_replacement(replacements, command)
  if type(command) == 'table' then
    local replacement = replacements[command[1]]
    if replacement then
      return { replacement, unpack(command, 2) }
    end
  end
  return replacements[command]
end

local function patch_keys(replacements)
  local _keys = {}
  for k, v in pairs(keys) do _keys[k] = v end

  for k, command in pairs(_keys) do
    local replacement = get_replacement(replacements, command)
    if replacement ~= nil then
      keys[k] = replacement
    end
  end
end

local ta_snapopen_open = ta.snapopen.open
local function snapopen_compat(utf8_paths, filter, exclude_FILTER, depth)
  if not utf8_paths or
     (type(utf8_paths) == 'table' and #utf8_paths ~= 1)
  then
    return ta_snapopen(utf8_paths, filter, exclude_FILTER, depth)
  end
  local directory = type(utf8_paths) == 'table' and utf8_paths[1] or utf8_paths
  fs.snapopen(directory, filter, exclude_FILTER, depth)
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

local replacements = {}

-- Hijack filteredlist for the below functions.
for _, target in ipairs({
  { gui,           'select_theme' },
  { ta.mime_types, 'select_lexer' },
  { menu,          'select_command' },
  { io,            'open_recent_file' },
  { ta.bookmarks,  'goto_bookmark' },
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
replacements[ta.snapopen.open] = snapopen_compat
ta.snapopen.open = snapopen_compat

-- Hijack open file and save_as.
replacements[io.open_file] = open_file_compat
io.open_file = open_file_compat
replacements[buffer.save_as] = save_as_compat
events.connect(events.BUFFER_NEW, function() buffer.save_as = save_as_compat end)

-- Finalize by patching keys.
patch_keys(replacements)
