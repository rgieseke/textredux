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
  i.e. open file, save file as well as snapopen functionality.
- @{textredux.ctags}. Displays a filtered list of symbols (functions,
  variables, …) in the current document using Exuberant Ctags.
- @{textredux.buffer_list}. A text based buffer list replacement, which in
  addition to being text based also offers an easy way to close buffers
  directly from the list.

## How to use it

Download and put the Textredux module in your `.textadept/modules/`
directory.

Having installed it, there are two ways you can use Textredux.

1) Cherrypick the functionality you want from the different modules by assigning
key bindings to the desired functions. As an example, if you would like to use
the text based file browser and normally opens files using `Ctr-O`, then the
following code in your `init.lua` would do the trick:

    local textredux = require('textredux')
    keys.co = textredux.fs.open_file

2) If you can't get enough of text based interfaces and the joy they provide,
then the Textredux {@hijack} function is for you. Simple place this in your
`init.lua`:

    require('textredux').hijack()

As the name suggest, Textredux has now hijacked your environment. All your
regular key bindings should now use Textredux where applicable. Clicking the
menu will still open the standard GUI dialogs.

## Customizing

Please see the documentation for the various modules for configuration settings.

@module textredux
]]

local M = {
  core = require 'textredux.core',
  buffer_list = require 'textredux.buffer_list',
  ctags = require 'textredux.ctags',
  fs = require 'textredux.fs'
}

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

---
-- Hijacks Textadept, replacing all keyboard shortcuts with text based
-- counterparts. Additionally, it replaces the traditional   filtered list
-- with a Textredux list for a number of operations.
function M.hijack()
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
    M.fs.snapopen(directory, filter, exclude_FILTER)
  end

  local io_open_file = io.open_file
  local function open_file_compat(utf8_filenames)
    if utf8_filenames then return io_open_file(utf8_filenames) end
    M.fs.open_file()
  end

  local io_save_file_as = io.save_file_as
  local save_as_compat
  function save_as_compat(buffer, utf8_filename)
    if utf8_filename then return io_save_file_as(buffer, utf8_filename) end
    -- temporarily restore the original save_as, since fs.save_buffer_as uses it
    -- in its implementation
    io.save_as = io_save_file_as
    local status, ret = pcall(M.fs.save_buffer_as)
    io.save_as = save_as_compat
    if not status then events.emit(events.ERROR, ret) end
  end

  -- Hijack filteredlist for the below functions.
  for _, target in ipairs({
    {textadept.file_types, 'select_lexer'},
    {textadept.menu, 'select_command'},
    {io, 'open_recent_file'},
    {textadept.bookmarks, 'goto_mark'},
  }) do
    local func = target[1][target[2]]
    local wrap = M.core.filteredlist.wrap(func)
    target[1][target[2]] = wrap
    replacements[func] = wrap
  end

  -- Hijack buffer list.
  replacements[ui.switch_buffer] = M.buffer_list.show
  ui.switch_buffer = M.buffer_list.show

  -- Hijack snapopen.
  replacements[io.snapopen] = snapopen_compat
  io.snapopen = snapopen_compat

  -- Hijack open file and save_as.
  replacements[io.open_file] = open_file_compat
  io.open_file = open_file_compat
  replacements[io.save_file_as] = save_as_compat

  -- Finalize by patching keys.
  patch_keys(replacements)

end

return M
