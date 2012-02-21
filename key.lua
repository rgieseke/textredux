--[[
Handles translation of key presses to Textadept key strings. Hopefully this
can be removed in the future if Textadept can be modified to export the
translation functionality.

This code is almost lifted verbatim from _M.textadept.keys, which has the
following copyright and license:

Copyright (c) 2007-2011 Mitchell

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

local string_char = string.char

local M = {}

-- settings
local ADD = ''
local CTRL = 'c'..ADD
local ALT = 'a'..ADD
local META = 'm'..ADD
local SHIFT = 's'..ADD

function M.translate(code, shift, control, alt, meta)
  local buffer = buffer
  local key
  if code < 256 then
    key = string_char(code)
    shift = false -- for printable characters, key is upper case
  else
    key = keys.KEYSYMS[code]
    if not key then return end
  end
  control = control and CTRL or ''
  alt = alt and ALT or ''
  meta = meta and OSX and META or ''
  shift = shift and SHIFT or ''
  local key_seq = control..alt..meta..shift..key
  return key_seq
end

return M
