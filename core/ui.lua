--[[-
The gui module handles GUI related operations for Textredux.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
@module textredux.core.ui
]]
local M = {}

--[[- Specifies the way that Textredux should split views.

Possible values are:

- `'horizontal'` : Prefer horizontal splits.
- `'vertical'` : Prefer vertical splits.
]]
M.view_split_preference = 'vertical'

function M.switch_to_other_view()
  if #_VIEWS ~= 1 then
    _G.ui.goto_view(1, true)
  else
    view:split(M.view_split_preference == 'vertical')
  end
end

return M
