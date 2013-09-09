--[[
This directory contains a few examples that show how to build text based
interfaces with the modules in `textredux.core`.

Provided that Textredux is installed you can paste the following line in
Textadept's command entry to show a list of examples:
    examples = require 'textredux.examples'; examples.show_examples()

 Alternatively, you can assign a key in your
`init.lua`. For example assign `Ctrl-3` to bring up the examples:
    _M.textredux.examples = require 'textredux.examples'
    keys['c3'] = _M.textredux.examples.show_examples
]]

_M.textredux = require 'textredux'

local M = {}

local basic_list = require 'textredux.examples.basic_list'
local buffer_actions = require 'textredux.examples.buffer_actions'
local buffer_indicators = require 'textredux.examples.buffer_indicators'
local buffer_styling = require 'textredux.examples.buffer_styling'
local list_commands = require 'textredux.examples.list_commands'
local multi_column_list = require 'textredux.examples.multi_column_list'
local styled_list = require 'textredux.examples.styled_list'

examples = {
  ['Basic list'] = basic_list.show_simple_list,
  ['Buffer actions'] = buffer_actions.create_action_buffer,
  ['Buffer styling'] = buffer_styling.create_styled_buffer,
  ['List commands'] = list_commands.show_action_list,
  ['Multi column list'] = multi_column_list.show_multi_column_list,
  ['Styled list'] = styled_list.show_styled_list
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
  local list = _M.textredux.core.list.new(
    'Textredux examples',
    keys,
    on_selection
  )
  list:show()
end

return M
