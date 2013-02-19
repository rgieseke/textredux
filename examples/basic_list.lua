--[[--
Very basic example on how to use the list class.

For the purpose of this example `Ctrl+3' will be set to show the
example buffer. Provided that Textredux is installed, you can run this
example by pasting `require 'textredux.examples.buffer_list'` into the
`Command entry` and then press `Ctrl+3` to try it out.

@author Nils Nordman <nino at nordman.org>
@copyright 2012
@license MIT (see LICENSE)
]]

require 'textadept'
_M.textredux = require 'textredux'

local function show_simple_list()
  -- create the list
  local list = _M.textredux.list.new(
    'Simple list', -- list title
    { 'one', 'two', 'three' }, -- list items
    function (list, item) -- on selection callback
      gui.statusbar_text = 'You selected ' .. item
    end
  )

  -- and show the list
  list:show()
end

keys['c3'] = show_simple_list
