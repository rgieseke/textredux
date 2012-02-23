--[[-
The gui module handles GUI related operations for TextRedux.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
@module _M.textredux.gui
]]
local M = {}

--[[- Specifies the way that TextRedux should split views.

Possible values are:

- `'horizontal'` : Prefer horizontal splits.
- `'vertical'` : Prefer vertical splits.
]]
M.view_split_preference = 'vertical'

function M.switch_to_other_view()
  if #_VIEWS ~= 1 then
    _G.gui.goto_view(1, true)
  else
    view:split(M.view_split_preference == 'vertical')
  end
end

return M
