-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The Textredux module allows you to easily create text based interfaces for the
[Textadept](http://foicica.com/textadept/) editor and offers a set of text
based interfaces.

It currently contains the following modules:

- @{textredux.core}. The core module provides basic components to create
  text based interfaces.
- @{textredux.fs}. Contains text based interfaces for file io operations,
  like open file, save file as well as snapopen functionality.
- @{textredux.ctags}. Displays a filtered list of symbols (functions,
  variables, …) in the current document using Exuberant Ctags.
- @{textredux.buffer_list}. A text based buffer list replacement, which in
  addition to being text based also offers an easy way to close buffers
  directly from the list.

## How to use it

Download and put the Textredux module in your `.textadept/modules/`
directory.

Having installed it, there are two (mixable) ways you can use Textredux.

1) Select the functionality you want from the different modules by assigning
keys to the desired functions.

    local textredux = require('textredux')
    keys.co = textredux.fs.open_file
    keys.cS = textredux.fs.save_buffer_as
    keys.cb = textredux.buffer_list.show
    keys.cg = textredux.ctags.goto_symbol

2) If you can't get enough of text based interfaces and the joy they provide,
then the @{hijack} function is for you. Simply place this in your
`init.lua`:

    require('textredux').hijack()

As the name suggest, Textredux has now hijacked your environment. All your
regular key bindings should now use Textredux where applicable. Clicking the
menu will still open the standard GUI dialogs.

## Customizing

Please see the modules documentation for more configuration settings.

@module textredux
]]

local M = {
  core = require 'textredux.core',
  buffer_list = require 'textredux.buffer_list',
  ctags = require 'textredux.ctags',
  fs = require 'textredux.fs'
}

-- Set new key bindings.
local function patch_keys(replacements)
  local _keys = {}
  for k, v in pairs(keys) do
    _keys[k] = v
  end
  for k, command_id in pairs(_keys) do
    local replacement = replacements[command_id]
    if replacement ~= nil then
      keys[k] = replacement
    end
  end
end

---
-- Hijacks Textadept, replacing all keyboard shortcuts with text based
-- counterparts. Additionally, it replaces the traditional filtered list
-- with a Textredux list for a number of operations.
function M.hijack()
  local m_file = textadept.menu.menubar[_L['File']]
  local m_tools = textadept.menu.menubar[_L['Tools']]
  local m_bookmark = m_tools[_L['Bookmarks']]

  local io_open = m_file[_L['Open']][2]

  local replacements = {}

  local io_quick_open = io.quick_open
  local function snapopen_compat(utf8_paths, filter, exclude_FILTER, ...)
    if not utf8_paths then utf8_paths = io.get_project_root() end
    if not utf8_paths and buffer.filename then
      utf8_paths = buffer.filename:match('^(.+)[/\\]')
    end
    if not utf8_paths or
       (type(utf8_paths) == 'table' and #utf8_paths ~= 1)
    then
      return io_quick_open(utf8_paths, filter, exclude_FILTER, ...)
    end
    local directory = type(utf8_paths) == 'table' and utf8_paths[1] or utf8_paths
    M.fs.snapopen(directory, filter, exclude_FILTER)
  end

  local io_open_file = io.open_file
  local function open_file_compat(utf8_filenames)
    if utf8_filenames then return io_open_file(utf8_filenames) end
    M.fs.open_file()
  end
  replacements[io_open] = open_file_compat

  -- Hijack filteredlist for the below functions.
  local select_command = m_tools[_L['Select Command']][2]
  local goto_mark = m_bookmark[_L['Goto Bookmark...']][2]
  local fl_funcs = {
    textadept.file_types.select_lexer,
    io.open_recent_file,
    select_command,
    goto_mark
  }

  for _, target in ipairs(fl_funcs) do
    local wrap = M.core.filteredlist.wrap(target)
    replacements[target] = wrap
  end

  -- Hijack buffer list.
  replacements[ui.switch_buffer] = M.buffer_list.show

  -- Hijack snapopen.
  replacements[io.quick_open] = snapopen_compat
  io.quick_open = snapopen_compat

  replacements[buffer.save] = M.fs.save_buffer
  replacements[buffer.save_as] = M.fs.save_buffer_as

  -- Finalize by patching keys.
  patch_keys(replacements)
end

return M
