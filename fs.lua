--[[--
textredux.fs provides a text based file browser for Textadept.

It features traditional directory browsing, snapopen functionality, completely
keyboard driven interaction, and provides powerful narrow to search functionality.

Some tips on using the file browser
-----------------------------------

*Switching between traditional browsing and snapopen*

As said above the file browser allows both traditional browsing as well as
snapopen functionality. But it also allows you to seamlessly switch between
the two modes (by default, `Ctrl + s` is assigned for this).

*Quickly moving up one directory level*

In traditional browsing mode, you can always select `..` to move up one directory
level. But a quicker way of doing the same is to press `<backspace>` when you
have an empty search. This also works when in snapopen mode.

*Opening a sub directory in snapopen mode*

In contrast with Textadept snapopen, you will in snapopen mode also see sub
directories in the listing. This is by design - you can select a sub directory
to snapopen that directory.

*Changing the styles used for different file types*

If you don't like the default styles (colors, etc.) used by the file browser,
you can easily change these by customizing any of the `style_<foo>` entries using
the TextUI style module. As an example, to make directory entries underlined
you would do something like the following:

    _M.textui.style.textredux_fs_directory = { underline = true }

Please see the documentation for the TextUI style module for instructions on how
to define styles.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textredux.fs
]]

local list = require('textui.list')
local style = require('textui.style')
local lfs = require('lfs')
local tr_gui = require 'textredux.gui'

local _G, table, io, gui = _G, table, io, gui
local ipairs, error, type, assert, pcall =
      ipairs, error, type, assert, pcall
local string_match, string_sub = string.match, string.sub

local _CHARSET, WIN32 = _CHARSET, WIN32
local ta_snapopen = _M.textadept.snapopen
local user_home = os.getenv('HOME') or os.getenv('UserProfile')
local fs_attributes = WIN32 and lfs.attributes or lfs.symlinkattributes
local separator = WIN32 and '\\' or '/'
local updir_pattern = '%.%.?$'

local M = {}
local _ENV = M
if setfenv then setfenv(1, _ENV) end

--- The style used for directory entries.
style.textredux_fs_directory = style.keyword

--- The style used for ordinary file entries.
style.textredux_fs_file = style.string

---  The style used for link entries.
style.textredux_fs_link = style.operator

--- The style used for socket entries.
style.textredux_fs_socket = style.error

--- The style used for pipe entries.
style.textredux_fs_pipe = style.error

--- The style used for pipe entries.
style.textredux_fs_device = style.error

local file_styles = {
  directory = style.textredux_fs_directory,
  file = style.textredux_fs_file,
  link = style.textredux_fs_link,
  socket = style.textredux_fs_socket,
  ['named pipe'] = style.textredux_fs_pipe,
  ['char device'] = style.textredux_fs_device,
  ['block device'] = style.textredux_fs_device,
  other = style.default
}

-- Splits a path into its components
function split_path(path)
  local parts = {}
  for part in path:gmatch('[^' .. separator .. ']+') do parts[#parts + 1] = part end
  return parts
end

-- Joins path components into a path
function join_path(components)
  local start = WIN32 and '' or separator
  return start .. table.concat(components, separator)
end

-- Returns the dir part of path
function dirname(path)
  local parts = split_path(path)
  table.remove(parts)
  local dir = join_path(parts)
  if #dir == 0 then return path end -- win32 root
  return dir
end

function basename(path)
  local parts = split_path(path)
  return parts[#parts]
end

-- Normalizes the path. This will deconstruct and reconstruct the
-- path's components, while removing any relative parent references
function normalize_path(path)
  local parts = split_path(path)
  local normalized = {}
  for _, part in ipairs(parts) do
    if part == '..' then
      table.remove(normalized)
    else
      normalized[#normalized + 1] = part
    end
  end
  if #normalized == 1 and WIN32 then normalized[#normalized + 1] = '' end -- TODO: win hack
  return join_path(normalized)
end

-- Normalizes a path denoting a directory. This will do the same as
-- normalize_path, but will in addition ensure that the path ends
-- with a trailing separator
function normalize_dir_path(directory)
  local path = normalize_path(directory)
  return string_sub(path, -1) == separator and path or path .. separator
end

local function parse_filters(filter)
  local filters = {}
  for _, restriction in ipairs(filter) do
    if type(restriction) == 'string' then
      local negated = restriction:match('^!(.+)')
      local filter_pattern = negated or restriction

      restriction = function(path)
        if path:match(filter_pattern) then
          if not negated then return true end
        elseif negated then return true
        else return false end
      end
    end
    filters[#filters + 1] = restriction
  end
  return filters
end

local function add_extensions_filter(filters, extensions)
  if extensions and #extensions > 0 then
    local exts = {}
    for _, ext in ipairs(extensions) do exts[ext] = true end
    filters[#filters + 1] = function(path)
      return exts[string_match(path, '%.(%a+)$')] ~= nil
    end
  end
end

---
-- Given the patterns, returns a function returning true if
-- the path should be filtered, and false otherwise
local function create_filter(filter)
  local filters = parse_filters(filter)
  add_extensions_filter(filters, filter.extensions)
  filters.directory = parse_filters(filter.folders or {})
  return function(file)
    local filters = filters[file.mode] or filters
    for _, filter in ipairs(filters) do
      if filter(file.path) then return true end
    end
    return false
  end
end

local function file(path, name, parent)
  local file, error = fs_attributes(path:iconv(_CHARSET, 'UTF-8'))
  if error then file = { mode = 'error' } end
  local suffix = file.mode == 'directory' and separator or ''
  file.path = path
  file.hidden = name and string_sub(name, 1, 1) == '.'
  if parent then
    file.rel_path = parent.rel_path .. name .. suffix
    file.depth = parent.depth + 1
  else
    file.rel_path = ''
    file.depth = 1
  end
  file[1] = file.rel_path
  return file
end

local function find_files(directory, filter, depth, max_files)
  if not directory then error('Missing argument #1 (directory)', 2) end
  if not depth then error('Missing argument #3 (depth)', 2) end

  if type(filter) ~= 'function' then filter = create_filter(filter) end
  local files = {}

  directory = normalize_path(directory)
  local directories = { file(directory) }
  while #directories > 0 do
    local dir = table.remove(directories)
    if dir.depth > 1 then files[#files + 1] = dir end
    if dir.depth <= depth then
      local status, entries = pcall(lfs.dir, dir.path:iconv(_CHARSET, 'UTF-8'))
      if status then
        for entry in entries do
          entry = entry:iconv('UTF-8', _CHARSET)
          local file = file(dir.path .. separator .. entry, entry, dir)
          if not filter(file) then
            if file.mode == 'directory' and entry ~= '..' and entry ~= '.' then
              table.insert(directories, 1, file)
            else
              if max_files and #files == max_files then return files, false end
              files[#files + 1] = file
            end
          end
        end
      end
    end
  end
  return files, true
end

local function sort_items(items)
  table.sort(items, function (a, b)
    local parent_path = '..' .. separator
    if a.rel_path == parent_path then return true
    elseif b.rel_path == parent_path then return false
    elseif a.hidden ~= b.hidden then return b.hidden
    elseif a.mode == 'directory' and b.mode ~= 'directory' then return true
    elseif b.mode == 'directory' and a.mode ~= 'directory' then return false
    end
    return (a.rel_path < b.rel_path)
  end)
end

local function chdir(list, directory)
  directory = normalize_path(directory)
  local data = list.data
  local items, complete = find_files(directory, data.filter, data.depth, data.max_files)
  if data.depth == 1 then sort_items(items) end
  list.title = directory
  list.items = items
  data.directory = directory
  list:show()
  if #items > 1 and items[1].rel_path:match('^%.%..?$') then
    list.buffer:line_down()
  end
  if not complete then
    local status = 'Number of entries limited to ' .. data.max_files .. ' as per snapopen.MAX'
    gui.statusbar_text = status
  else
    gui.statusbar_text = ''
  end
end

local function open_selected_file(path, exists, list, shift, ctrl)
  if not exists then
    local file, error = io.open(path:iconv(_CHARSET, 'UTF-8'), 'wb')
    if not file then
      gui.statusbar_text = 'Could not create ' .. path .. ': ' .. error
      return
    end
    file:close()
  end
  list:close()
  if ctrl then tr_gui.switch_to_other_view() end
  io.open_file(path)
end

function on_keypress(list, key, code, shift, ctl, alt, meta)
  if ctl or alt or meta or not key then return end
  if key == '\b' and not list:get_current_search() then
    local parent = dirname(list.data.directory)
    if parent ~= list.data.directory then
      chdir(list, parent)
      return true
    end
  end
end

local function get_initial_directory()
  local filename = _G.buffer.filename
  if filename then return dirname(filename) end
  return user_home
end

local function get_file_style(item, index)
  return file_styles[item.mode] or style.default
end

local function toggle_snap(list)
  local data = list.data
  local depth = data.depth

  if data.prev_depth then
    data.depth = data.prev_depth
  else
    data.depth = data.depth == 1 and ta_snapopen.DEFAULT_DEPTH or 1
  end

  local filter = data.filter
  if data.depth == 1 then -- remove updir filter
    if type(filter.folders) == 'table' then
      for i, restriction in ipairs(filter.folders) do
        if restriction == updir_pattern then
          table.remove(filter.folders, i)
          break
        end
      end
    end
  else -- add updir filter
    filter.folders = filter.folders or {}
    filter.folders[#filter.folders + 1] = updir_pattern
  end
  data.prev_depth = depth
  chdir(list, data.directory)
end

local function create_list(directory, filter, depth, max_files)
  local list = list.new(directory)
  local data = list.data
  list.on_keypress = on_keypress
  list.column_styles[1] = get_file_style
  list.keys.esc = function() list:close() end
  list.keys.cs = toggle_snap
  data.directory = directory
  data.filter = filter
  data.depth = depth
  data.max_files = max_files
  return list
end

--[[- Opens a file browser and lets the user choose a file.
@param on_selection The function to invoke when the user has choosen a file. The function
will be called with following parameters:

- `path`: The full path of the choosen file (UTF-8 encoded).
- `exists`: A boolean indicating whether the file exists or not.
- `list`: A reference to the TextUI list used by browser.
- `shift`: True if the Shift key was held down when selecting the file.
- `ctrl`: True if the Control/Command key was held down when selecting the file.
- `alt`: True if the Alt/option key was held down when selecting the file.
- `meta`: True if the Control key on Mac OSX was held down when selecting the file.

The list will not be closed automatically, so close it explicitly using
`list:close()` if desired.

@param start_directory The initial directory to open, in UTF-8 encoding. If nil,
the initial directory is determined automatically (preferred choice is to
open the directory containing the current file).
@param filter The filter to apply, if any. The structure and semantics are the
same as for Textadept's
[snapopen](http://caladbolg.net/luadoc/textadept/modules/_m.textadept.snapopen.html).
@param depth The number of directory levels to display in the list. Defaults to
1 if not specified, which results in a "normal" directory listing.
@param max_files The maximum number of files to scan and display in the list.
Defaults to 10000 if not specified.
]]
function select_file(on_selection, start_directory, filter, depth, max_files)
  start_directory = start_directory or get_initial_directory()
  if not filter then filter = {}
  elseif type(filter) == 'string' then filter = { filter } end

  filter.folders = filter.folders or {}
  filter.folders[#filter.folders + 1] = separator .. '%.$'

  local list = create_list(start_directory, filter, depth or 1, max_files or 10000)

  list.on_selection = function(list, item, shift, ctrl, alt, meta)
    local path, mode = item.path, item.mode
      if mode == 'link' then mode = lfs.attributes(path:iconv(_CHARSET, 'UTF-8'), 'mode') end
      if mode == 'directory' then
        chdir(list, path)
      else
        on_selection(path, true, list, shift, ctrl, alt, meta)
      end
  end

  list.on_new_selection = function(list, name, shift, ctrl, alt, meta)
    local path = split_path(list.data.directory)
    path[#path + 1] = name
    on_selection(join_path(path), false, list, shift, ctrl, alt, meta)
  end

  chdir(list, start_directory)
end

--- Opens the specified directory for browsing.
-- @param start_directory The directory to open, in UTF-8 encoding
function open_file(start_directory)
  local filter = { folders = { separator .. '%.$' } }
  select_file(open_selected_file, start_directory, filter, 1, ta_snapopen.MAX)
end

--- Saves the current buffer under a new name.
-- Open a browser and lets the user select a name.
function save_buffer_as()
  local buffer = _G.buffer
  local confirm_path

  local function set_file_name(path, exists, list)
    if not exists or path == confirm_path then
      list:close()
      _G.view:goto_buffer(_G._BUFFERS[buffer], false)
      buffer:save_as(path)
      gui.statusbar_text = ''
    else
      gui.statusbar_text = 'File exists (' .. path .. '): Press enter to overwrite.'
      confirm_path = path
    end
  end
  local filter = { folders = { separator .. '%.$' } }
  select_file(set_file_name, nil, filter, 1)
  gui.statusbar_text = 'Save file: select file name to save as..'

end

--- Saves the current buffer.
-- Prompts the users for a filename if it's a new, previously unsaved buffer.
function save_buffer()
  local buffer = _G.buffer
  if buffer.filename then
    buffer:save()
  else
    save_buffer_as()
  end
end

--[[-
Opens a list of files in the specified directory, according to the given
parameters. This works similarily to
[Textadept snapopen](http://caladbolg.net/luadoc/textadept/modules/_m.textadept.snapopen.html).
The main differences are:

- it does not support opening multiple paths at once, which also makes the
  Textadept parameter `exclusive` pointless.
- filter can contain functions as well as patterns (and can be a function as well).
  Functions will be passed a file object which is the same as the return from
  [lfs.attributes](http://keplerproject.github.com/luafilesystem/manual.html#attributes),
  with the following additions:

    - `rel_path`: The path of the file relative to the currently displayed directory.
    - `hidden`: Whether the path denotes a hidden file.

@param directory The directory to open, in UTF-8 encoding.
@param filter The filter to apply. The format and semantics are the same as for
Textadept.
@param exclude_FILTER Same as for Textadept: unless if not true then
snapopen.FILTER will be automatically added to the filter.
to snapopen.FILTER if not specified.
@param depth The number of directory levels to scan. Same as for Textadept,
and also defaults to snapopen.DEFAULT_DEPTH if not specified.
]]
function snapopen(directory, filter, exclude_FILTER, depth)
  if not directory then error('directory not specified', 2) end
  if not depth then depth = ta_snapopen.DEFAULT_DEPTH end
  filter = filter or {}
  if type(filter) == 'string' then filter = { filter } end
  filter.folders = filter.folders or {}
  filter.folders[#filter.folders + 1] = updir_pattern

  if not exclude_FILTER then
    for _, key in ipairs({ 'folders', 'extensions' }) do
      filter[key] = filter[key] or {}
      for _, pattern in ipairs(ta_snapopen.FILTER[key]) do
        filter[key][#filter[key] + 1] = pattern
      end
    end
  end

  select_file(open_selected_file, directory, filter, depth, ta_snapopen.MAX)
end

return M
