-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
Display a list of files under revision control in a Git repository. Uses
Textadept's `io.get_project_root` function to find the root directory.
]]

local M = {}

local textredux = require('textredux')
local reduxlist = textredux.core.list

function M.show_files()
  if not buffer.filename then return end
  local files = {}
  local current_dir = lfs.currentdir()
  local working_dir = io.get_project_root()
  if not working_dir then return end
  lfs.chdir(working_dir)
  ui.statusbar_text = lfs.currentdir()
  local p = io.popen('git ls-files')
  for line in p:lines() do
    files[#files + 1] = line
  end
  p:close()
  lfs.chdir(current_dir)
  if #files > 0 then
    local list = reduxlist.new('Git: '..working_dir)
    list.items = files
    list.on_selection = function(list, item)
      if item then io.open_file(working_dir..'/'..item) end
    end
    list:show()
  end
end

return M
