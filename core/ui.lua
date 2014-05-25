-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The ui module handles UI related operations for Textredux.

@module textredux.core.ui
]]
local M = {}

---
-- Specifies the way that Textredux should split views.
-- Possible values are:
-- - `'horizontal'` : Prefer horizontal splits.
-- - `'vertical'` : Prefer vertical splits.
M.view_split_preference = 'vertical'

function M.switch_to_other_view()
  if #_VIEWS ~= 1 then
    _G.ui.goto_view(1, true)
  else
    view:split(M.view_split_preference == 'vertical')
  end
end

return M
