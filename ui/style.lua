--[[--
The style module lets you define and use custom, non-lexer-based styles.

The default styles
------------------

Textredux piggybacks on the default lexer styles defined by a user's theme,
and makes them available for your Textredux interface. The big benefit of this
is that by using those styles, or by basing your custom styles on them, your
interface stands a much higher chance of blending in well with the color scheme
used. As an example, your custom style with cyan foreground text might look
great with your own dark theme, but may be pretty near invisible for some user
with a light blue background.

You can read more about the default lexer styles
[here](http://foicica.com/textadept/api/lexer.html).
You access a default style (or any style for that matter), by indexing the
style module, like so: `style.<name>`. For reference, the default styles
available are these:

- style.nothing
- style.whitespace
- style.comment
- style.string
- style.number
- style.keyword
- style.identifier
- style.operator
- style.error
- style.preproc
- style.constant
- style.variable
- style.function
- style.class
- style.type
- style.default
- style.line_number
- style.bracelight
- style.bracebad
- style.controlchar
- style.indentguide
- style.calltip

What's a style?
---------------

Textredux styling has been made to resemble the lexer based style creation.
A style is thus just a table with certain properties, almost exactly the same as
for style created for a lexer or theme. Please see the documentation for
[lexer.style](http://foicica.com/textadept/api/lexer.html#style)
for information about the fields. The one exception compared to lexer styles
is that colors are specified using the standard `'#rrggbb'` notation instead of
the lexer styles' `bgr` notation. This is what you use to create custom styles
(see below), and also what you get when accessing any already existing styles.

Defining styles
---------------

You define a new style by assigning the style to the style module, like so:

    style.foo_header = { italic = true, fore = '#680000' }

As has been previously said, it's often a good idea to base your custom styles
on an existing default style. Similarily to defining a lexer style in Textadept
you can achieve this by concatenating styles:

    style.foo_header = style.string .. { underline = true }

*NB:* Watch out for the mistake of not assigning the style to the style module:

    local header = style.string .. { underline = true }

This will _not_ work, as the style is not correctly defined with the style module.

In order to avoid name clashes, it's suggested that you name any custom styles
by prefixing their name with the name of your module. E.g. if your module is named
`awesome`, then name your style something like `style.awesome_style`.

Using styles
------------

You typically use a style by inserting text through @{_M. .buffer}'s text insertion
methods, specifying the style. Please see the examples in @{buffer_styling.lua}
for examples on this.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textredux.style
]]

local _G, pairs, setmetatable, error, tonumber =
      _G, pairs, setmetatable, error, tonumber
local string_format = string.format

local M = {}
local _ENV = M
if setfenv then setfenv(1, _ENV) end

-- The largest available style number
local STYLE_MAX = 127

local default_styles = {
  nothing = 0,
  whitespace = 1,
  comment = 2,
  string = 3,
  number = 4,
  keyword = 5,
  identifier = 6,
  operator = 7,
  error = 8,
  preproc = 9,
  constant = 10,
  variable = 11,
  ['function'] = 12,
  class = 13,
  type = 14,
  default = 32,
  line_number = 33,
  bracelight = 34,
  bracebad = 35,
  controlchar = 36,
  indentguide = 37,
  calltip = 38
}
local styles = {}
local buffer_styles = {}
setmetatable(buffer_styles, { __mode = 'k' })

local function table_copy(table)
  local new = {}
  for k, v in pairs(table) do new[k] = v end
  return new
end

local function style_merge(s1, s2)
  local new = table_copy(s1)
  for k, v in pairs(s2) do new[k] = v end
  new.number = nil
  return new
end

local function string_to_color(rgb)
  if not rgb then return nil end
  local r, g, b = rgb:match('^#?(%x%x)(%x%x)(%x%x)$')
  if not r then error("Invalid color specification '" .. rgb .. "'", 2) end
  return tonumber(b .. g .. r, 16)
end

local function color_to_string(color)
  local hex = string_format('%.6x', color)
  local b, g, r = hex:match('^(%x%x)(%x%x)(%x%x)$')
  if not r then return '?' end
  return '#' .. r .. g .. b
end

--
-- Gets a style definition for the specified style (number)
-- @param number The style number to get the definition for
-- @param name (Optional) name of the style if known
-- @return a style definition (table)
local function get_definition(number, name)
  if number < 0 or number > STYLE_MAX then error('invalid style number "'.. number .. '"', 2) end
  local buffer = _G.buffer
  local style = {
    font = buffer.style_font[number],
    size = buffer.style_size[number],
    bold = buffer.style_bold[number],
    italic = buffer.style_italic[number],
    underline = buffer.style_underline[number],
    fore = color_to_string(buffer.style_fore[number]),
    back = color_to_string(buffer.style_back[number]),
    eolfilled = buffer.style_eol_filled[number],
    characterset = buffer.style_character_set[number],
    case = buffer.style_case[number],
    visible = buffer.style_visible[number],
    changeable = buffer.style_changeable[number],
    hotspot = buffer.style_hot_spot[number],
    name = name or buffer:get_style_name(number),
    number = number
  }
  setmetatable(style, {__concat = style_merge})
  return style
end

local function set_style_property(table, number, value)
  if value ~= nil then table[number] = value end
end

--
-- Defines a style using the specified style number
-- @param number The style number that should be used for the style
-- @param style The style definition
local function define_style(number, style)
  local buffer = _G.buffer
  set_style_property(buffer.style_size, number, style.size)
  set_style_property(buffer.style_bold, number, style.bold)
  set_style_property(buffer.style_italic, number, style.italic)
  set_style_property(buffer.style_underline, number, style.underline)
  set_style_property(buffer.style_fore, number, string_to_color(style.fore))
  set_style_property(buffer.style_back, number, string_to_color(style.back))
  set_style_property(buffer.style_eol_filled, number, style.eolfilled)
  set_style_property(buffer.style_character_set, number, style.characterset)
  set_style_property(buffer.style_case, number, style.case)
  set_style_property(buffer.style_visible, number, style.visible)
  set_style_property(buffer.style_changeable, number, style.changeable)
  set_style_property(buffer.style_hot_spot, number, style.hotspot)
  set_style_property(buffer.style_font, number, style.font)
end

local function get_buffer_styles()
  local buffer = _G.buffer
  local styles = buffer_styles[buffer]
  if styles then return styles end
  styles = { _last_number = STYLE_MAX + 1 }
  buffer_styles[buffer] = styles
  return styles
end

--
-- Retrieves the style number used for the specified style
-- in the current buffer. The style will automatically be
-- defined in the current buffer if it isn't already.
-- @param style The style definition to get the style number for.
local function get_style_number(style)
  if style.number then return style.number end -- a default style
  local styles = get_buffer_styles()
  if styles[style.name] then return styles[style.name] end
  styles._last_number = styles._last_number - 1
  define_style(styles._last_number, style)
  styles[style.name] = styles._last_number
  return styles._last_number
end

---
-- Applies the specified style for the given text range and buffer.
-- While you could use this directly, you'd typically use the text insertion
-- methods in @{_M.textredux.buffer} to style content.
-- @param style The defined style
-- @param buffer The buffer to apply the style for
-- @param start_pos The starting position of the style
-- @param length The number of positions to style
function apply(style, buffer, start_pos, length)
  buffer:start_styling(start_pos, 0xff)
  buffer:set_styling(length, get_style_number(style))
end

---
-- Defines the currently used custom styles for the current buffer.
-- This must be called whenever a buffer with custom styles is switched to.
-- This is automatically done by the @{_M.textredux.buffer} class, and thus
-- not something you typically have to worry about.
function define_styles()
  local buffer_styles = get_buffer_styles()
  for name, number in pairs(buffer_styles) do
    local style = styles[name]
    if style then
      define_style(number, style)
    end
  end
end

---
-- Gets a list of currently defined styles
-- @return a table of style definitions
local function get_current_styles()
  local buffer_styles = {}
  for name, number in pairs(default_styles) do
    buffer_styles[#buffer_styles + 1] = styles[name]
  end
  return buffer_styles
end

local function set_style(_, name, style)
  style = table_copy(style)
  style.name = name
  style.number = nil -- ignore any style number set since this is a new style
  setmetatable(style, {__concat = style_merge})
  styles[name] = style
end

for name, number in pairs(default_styles) do
  styles[name] = get_definition(number, name)
end

setmetatable(M, {__index = styles, __newindex = set_style})
return M
