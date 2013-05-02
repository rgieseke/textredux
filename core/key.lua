--[[
Handles translation of key presses to Textadept key strings. Hopefully this
can be removed in the future if Textadept can be modified to export the
translation functionality.

This code is almost lifted verbatim from _M.textadept.keys, which has the
following copyright and license:

Copyright (c) 2007-2013 Mitchell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
--]]

local M = {}

-- Settings.
local ADD = ''
local CTRL = 'c'..ADD
local ALT = 'a'..ADD
local META = 'm'..ADD
local SHIFT = 's'..ADD

function M.translate(code, shift, control, alt, meta)
  if code == 13 then return '\n' end -- workaround for curses version
  local key
  if code < 256 and (not CURSES or code ~= 7) then
    key = string.char(code)
  else
    key = _G.keys.KEYSYMS[code]
  end
  if not key then return end
  shift = shift and (code >= 256 or code == 9) -- printable chars are uppercased
  local key_seq = (control and CTRL or '')..(alt and ALT or '')..
                  (meta and OSX and META or '')..(shift and SHIFT or '')..key
  return key_seq
end

return M
