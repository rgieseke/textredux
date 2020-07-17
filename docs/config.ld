-- ldoc configuration file
title = 'Textredux API Docs'
project = 'Textredux'
file = {
  '../init.lua',
  '../fs.lua',
  '../ctags.lua',
  '../buffer_list.lua',
  '../core',
  '../util'
}
format = 'markdown'
style = true
backtick_references = false
description = [[
Text-based interfaces for Textadept.
]]
output = 'api'
template = '.'
dir = '.'
alias("p","param")
