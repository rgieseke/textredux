_M.textile = require 'textile'

local fl = require 'textile.takeover.filteredlist'
local fs = _M.textile.fs

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

local function patch_sub_menu(menu, replacements)
  for _, entry in ipairs(menu) do
    if entry.title then patch_sub_menu(entry, replacements)
    else
      local command = entry[2]
      local replacement = get_replacement(replacements, command)
      if replacement ~= nil then
        entry[2] = replacement
      end
    end
  end
end

local function patch_menu(replacements)
  local menubar = menu.menubar
  for _, menu in ipairs(menubar) do patch_sub_menu(menu, replacements) end
  menu.set_menubar(menubar)
  menu.rebuild_command_tables()
end

local ta_snapopen_open = ta.snapopen.open
local function snapopen_compat(utf8_paths, filter, exclude_PATHS, exclude_FILTER, depth)
  if not utf8_paths or
     (type(utf8_paths) == 'table' and #utf8_paths ~= 1) or
     (not exclude_PATHS and #ta.snapopen.PATHS > 1)
  then
    return ta_snapopen(utf8_paths, filter, exclude_PATHS, exclude_FILTER, depth)
  end
  local directory = type(utf8_paths) == 'table' and utf8_paths[1] or utf8_paths
  fs.snapopen(directory, filter, exclude_FILTER, depth)
end

local replacements = {}

-- Take over filteredlist for the below functions
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

-- Take over buffer list
replacements[gui.switch_buffer] = _M.textile.buffer_list.show
gui.switch_buffer = _M.textile.buffer_list.show

-- Take over snapopen
replacements[ta.snapopen.open] = snapopen_compat
ta.snapopen.open = snapopen_compat

patch_keys(replacements)
patch_menu(replacements)
