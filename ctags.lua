-- For supported filetypes, displays a filtered list dialog with symbols
-- in the current document using
-- [Exuberant Ctags](http://ctags.sourceforge.net/).
-- Note that it is possible to add support for additional filetypes, for
-- example for Latex:
-- In `~/.ctags`:
--
--     --langdef=latex
--     --langmap=latex:.tex
--     --regex-latex=/\\label\{([^}]*)\}/\1/l,label/
--     --regex-latex=/\\section\{([^}]*)\}/\1/s,section/
--     --regex-latex=/\\subsection\{([^}]*)\}/\1/t,subsection/
--     --regex-latex=/\\subsubsection\{([^}]*)\}/\1/u,subsubsection/
--     --regex-latex=/\\section\*\{([^}]*)\}/\1/s,section/
--     --regex-latex=/\\subsection\*\{([^}]*)\}/\1/t,subsection/
--     --regex-latex=/\\subsubsection\*\{([^}]*)\}/\1/u,subsubsection/
--
-- Based on Mitchell's ctags code posted on the
-- [Textadept wiki](http://foicica.com/wiki/ctags).

_M.textredux = require 'textredux'

local M = {}

-- Path and options for the ctags utility can be defined in the `CTAGS`
-- field.
if WIN32 then
  M.CTAGS = '"c:\\program files\\ctags\\ctags.exe" --sort=yes --fields=+K-f'
else
  M.CTAGS = 'ctags --sort=yes --fields=+K-f'
end

local function on_selection(list, item)
  local line = item[3]
  if line then
    list:close()
    _G.buffer:goto_line(tonumber(line) - 1)
    _G.buffer:vertical_centre_caret()
  end
end

-- Goes to the selected symbol in a filtered list dialog.
-- Requires [ctags]((http://ctags.sourceforge.net/)) to be installed.
function M.goto_symbol()
  if not buffer.filename then return end
  local symbols = {}
  local p = io.popen(M.CTAGS..' --excmd=number -f - "'..buffer.filename..'"')
  for line in p:read('*all'):gmatch('[^\r\n]+') do
    local name, line, ext = line:match('^(%S+)\t[^\t]+\t([^;]+);"\t(.+)$')
    if name and line and ext then
      symbols[#symbols + 1] = {name, ext, line}
    end
  end
  p:close()
  if #symbols > 0 then
    local list = _M.textredux.core.list.new('Go to symbol')
    list.keys['esc'] = function(list) list:close() end
    list.items = symbols
    list.on_selection = on_selection
    list:show()
  end
end

return M
