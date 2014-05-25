-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[
This directory contains a few examples that show how to build text based
interfaces with the modules in `textredux.core`.

When Textredux is installed you can paste the following line in
Textadept's command entry to show a list of examples:

    examples = require('textredux.examples').show_examples()

to select from a list of examples.
]]

local M = {}

local textredux = require 'textredux'

M.basic_list = require 'textredux.examples.basic_list'
M.buffer_actions = require 'textredux.examples.buffer_actions'
M.buffer_indicators = require 'textredux.examples.buffer_indicators'
M.buffer_styling = require 'textredux.examples.buffer_styling'
M.list_commands = require 'textredux.examples.list_commands'
M.multi_column_list = require 'textredux.examples.multi_column_list'
M.styled_list = require 'textredux.examples.styled_list'

examples = {
  ['Buffer styling'] = M.buffer_styling.create_styled_buffer,
  ['Basic list'] = M.basic_list.show_simple_list,
  ['Buffer indicators'] = M.buffer_indicators.create_indicator_buffer,
  ['Styled list'] = M.styled_list.show_styled_list,
  ['List commands'] = M.list_commands.show_action_list,
  ['Multi column list'] = M.multi_column_list.show_multi_column_list,
  ['Buffer actions'] = M.buffer_actions.create_action_buffer
}

local keys = {}
for k, v in pairs(examples) do
  keys[#keys+1] = k
end

local function on_selection(list, item)
  ui.statusbar_text = item
  examples[item]()
end

function M.show_examples()
  local list = textredux.core.list.new(
    'Textredux examples',
    keys,
    on_selection
  )
  list:show()
end

return M
