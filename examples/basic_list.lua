--[[--
Very basic example on how to use the list class.
-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

textredux = require 'textredux'

local M = {}

function M.show_simple_list()
  -- create the list
  local list = textredux.core.list.new(
    'Simple list', -- list title
    { 'one', 'two', 'three' }, -- list items
    function (list, item) -- on selection callback
      ui.statusbar_text = 'You selected ' .. item
    end
  )

  -- and show the list
  list:show()
end

return M
