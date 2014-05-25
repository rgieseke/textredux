-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

-- Very basic example on how to use the list class.

local M = {}

local textredux = require 'textredux'

function M.show_simple_list()
  -- Create the list.
  local list = textredux.core.list.new(
    'Simple list', -- list title
    {'one', 'two', 'three'}, -- list items
    function (list, item) -- on selection callback
      ui.statusbar_text = 'You selected ' .. item
    end
  )

  -- Show the list.
  list:show()
end

return M
