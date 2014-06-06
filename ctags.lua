-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
Displays a filtered list of symbols (functions, variables, …) in the current
document using [Exuberant Ctags](http://ctags.sourceforge.net/).

Usage
-----

In your init.lua:

    events.connect(events.INITIALIZED, function()
      local textredux = require 'textredux'
      keys.cg = textredux.ctags.goto_symbol -- Ctrl+G
    end)

Requirements
------------

Exuberant Ctags needs to be installed and is available in the
usual package managers.

Debian/Ubuntu:

    sudo apt-get install exuberant-ctags

Homebrew on OS X:

    brew install ctags

Note that it is possible to add support for additional filetypes in your
`~/.ctags`, for example LaTeX:

    --langdef=latex
    --langmap=latex:.tex
    --regex-latex=/\\label\{([^}]*)\}/\1/l,label/
    --regex-latex=/\\section\{([^}]*)\}/\1/s,section/
    --regex-latex=/\\subsection\{([^}]*)\}/\1/t,subsection/
    --regex-latex=/\\subsubsection\{([^}]*)\}/\1/u,subsubsection/
    --regex-latex=/\\section\*\{([^}]*)\}/\1/s,section/
    --regex-latex=/\\subsection\*\{([^}]*)\}/\1/t,subsection/
    --regex-latex=/\\subsubsection\*\{([^}]*)\}/\1/u,subsubsection/

This module is based on Mitchell's ctags code posted on the
[Textadept wiki](http://foicica.com/wiki/ctags).

@module textredux.ctags
]]

local M = {}

local reduxstyle = require 'textredux.core.style'
local reduxlist = require 'textredux.core.list'

---
-- Path and options for the ctags call can be defined in the `CTAGS`
-- field.
M.CTAGS = 'ctags --sort=yes --fields=+K-f'

---
-- Mappings from Ctags kind to Textredux styles.
M.styles = {
  class = reduxstyle.class,
  enum = reduxstyle['type'],
  enumerator = reduxstyle['type'],
  ['function'] = reduxstyle['function'],
  macro = reduxstyle.operator,
  namespace = reduxstyle.preproc,
  typedef = reduxstyle.keyword,
  variable = reduxstyle.variable
}

-- Close the Textredux list and jump to the selected line in the origin buffer.
local function on_selection(list, item)
  local line = item[3]
  if line then
    ui.statusbar_text = line
    list:close()
    buffer:goto_line(tonumber(line) - 1)
    buffer:vertical_centre_caret()
  end
end

-- Return color for Ctags kind.
local function get_item_style(item, column_index)
  -- Use a capture to find fields like `function namespace:…`.
  local kind = item[2]:match('(%a+)%s?')
  return M.styles[kind] or reduxstyle.default
end

---
-- Goes to the selected symbol in a filtered list dialog.
-- Requires [ctags]((http://ctags.sourceforge.net/)) to be installed.
function M.goto_symbol()
  if not buffer.filename then return end
  local symbols = {}
  local p = io.popen(M.CTAGS..' --sort=no --excmd=number -f - "'..buffer.filename..'"')
  for line in p:read('*all'):gmatch('[^\r\n]+') do
    local name, line, ext = line:match('^(%S+)\t[^\t]+\t([^;]+);"\t(.+)$')
    if name and line and ext then
      symbols[#symbols + 1] = {name, ext, line}
    end
  end
  p:close()
  if #symbols > 0 then
    local list = textredux.core.list.new('Go to symbol')
    list.items = symbols
    list.on_selection = on_selection
    list.column_styles = { reduxstyle.default, get_item_style }
    list:show()
  end
end

return M
