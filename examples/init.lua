--[[
This directory contains a few examples that show how to build text based
interfaces with the modules in `textredux.core`.

Provided that Textredux is installed you can paste the following line in
Textadept's command entry to show a list of examples:
    examples = require 'textredux.examples'; examples.show_examples()

 Alternatively, you can assign a key in your
`init.lua`. For example assign `Ctrl-3` to bring up the examples:
    textredux.examples = require 'textredux.examples'
    keys['c3'] = textredux.examples.show_examples
]]

textredux = require 'textredux'

local M = {}

M.basic_list = require 'textredux.examples.basic_list'
M.buffer_actions = require 'textredux.examples.buffer_actions'
M.buffer_indicators = require 'textredux.examples.buffer_indicators'
M.buffer_styling = require 'textredux.examples.buffer_styling'
M.list_commands = require 'textredux.examples.list_commands'
M.multi_column_list = require 'textredux.examples.multi_column_list'
M.styled_list = require 'textredux.examples.styled_list'

examples = {
  ['Basic list'] = M.basic_list.show_simple_list,
  ['Buffer actions'] = M.buffer_actions.create_action_buffer,
  ['Buffer styling'] = M.buffer_styling.create_styled_buffer,
  ['List commands'] = M.list_commands.show_action_list,
  ['Multi column list'] = M.multi_column_list.show_multi_column_list,
  ['Styled list'] = M.styled_list.show_styled_list
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
