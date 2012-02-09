_M.textile = require 'textile'
local fl = require 'textile.takeover.filteredlist'

local ta = _M.textadept
local menu = ta.menu

local function patch_keys(replacements)
  local _keys = {}
  for k, f in pairs(keys) do _keys[k] = f end

  for k, f in pairs(_keys) do
    local replacement = replacements[f]
    if replacement ~= nil then
      keys[k] = replacement
    end
  end
end

local function patch_menu(replacements)
  local menubar = menu.menubar

  for _, menu in ipairs(menubar) do
    for _, entry in ipairs(menu) do
      local f = entry[2]
      local replacement = replacements[f]
      if replacement ~= nil then
        entry[2] = replacement
      end
    end
  end

  menu.set_menubar(menubar)
  menu.rebuild_command_tables()
end

local replacements = {}

for _, target in ipairs({
  {gui, 'select_theme'},
  {ta.mime_types, 'select_lexer'},
  {menu, 'select_command'},
  {io, 'open_recent_file'},
  {ta.bookmarks, 'goto_bookmark'},

}) do
  local func = target[1][target[2]]
  local wrap = fl.wrap(func)
  target[1][target[2]] = wrap
  replacements[func] = wrap
end

patch_keys(replacements)
patch_menu(replacements)
