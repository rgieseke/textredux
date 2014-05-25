-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The style module lets you define and use custom, non-lexer-based styles.

What's a style?
---------------

Textredux styling provides an abstraction layer over the lexer based style
creation. A style is thus just a table with certain properties, almost exactly
the same as for style created for a lexer or theme. Please see the documentation
for
[lexer.style](http://foicica.com/textadept/api/lexer.html#Styles.and.Styling)
for information about the available fields. Colors should be defined in the
standard `'#rrggbb'` notation.

Defining styles
---------------

You define a new style by assigning a table with its properties to the module:

    local reduxstyle = require 'textredux.core.style'
    reduxstyle.foo_header = { italic = true, fore = '#680000' }

As has been previously said, it's often a good idea to base your custom styles
on an existing default style. Similarily to defining a lexer style in Textadept
you can achieve this by concatenating styles:

    reduxstyle.foo_header = style.string .. { underline = true }

*NB:* Watch out for the mistake of assigning the style to a local variable:

    local header = reduxstyle.string .. { underline = true }

This will _not_ work, as the style is not correctly defined with the style
module, necessary to ensure styles are correctly defined when new buffers
are created.

In order to avoid name clashes, it's suggested that you name any custom styles
by prefixing their name with the name of your module. E.g. if your module is
named `awesome`, then name your style something like `style.awesome_style`.

Using styles
------------

You typically use a style by inserting text through
@{textredux.core.buffer}'s text insertion methods, specifying the style.
Please see also the example in `examples/buffer_styling.lua`.

  reduxbuffer:add_text('Foo header text', reduxstyle.foo_header)

The default styles
------------------

Textredux piggybacks on the default lexer styles defined by a user's theme,
and makes them available for your Textredux interfaces. The big benefit of this
is that by using those styles or basing your custom styles on them, your
interface stands a much higher chance of blending in well with the color scheme
used. As an example, your custom style with cyan foreground text might look
great with your own dark theme, but may be pretty near invisible for some user
with a light blue background.

You can read more about the default lexer styles in the
[Textadept lexer documentation](http://foicica.com/textadept/api/lexer.html).
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

@module textredux.core.style
]]

local M = {}

local color = require 'textredux.util.color'
local string_to_color = color.string_to_color
local color_to_string = color.color_to_string

local STYLE_LASTPREDEFINED = buffer.STYLE_LASTPREDEFINED
local STYLE_MAX = buffer.STYLE_MAX

---
-- Applies a style.
-- Attached to each style defined in the module.
-- @param self The Style
-- @param start_pos The start position
-- @param length The number of chars to style
local function apply(self, start_pos, length)
  local buffer = buffer
  buffer:start_styling(start_pos, 0xff)
  buffer:set_styling(length, self.number)
end


-- Copy a table.
local function table_copy(table)
  local new = {}
  for k, v in pairs(table) do new[k] = v end
  return new
end

-- Overwrite fields in first style table with fields from second style table.
local function style_merge(s1, s2)
  local new = table_copy(s1)
  for k, v in pairs(s2) do new[k] = v end
  new.number = nil
  return new
end

-- Pre-defined style numbers.
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

-- Number of pre-defined styles. Used to calculate new style numbers.
local count_default_styles = 0
for _, _ in pairs(default_styles) do
  count_default_styles = count_default_styles + 1
end

-- Gets a style definition for the specified style (number).
-- Returns a style definition (table)
local function get_definition(number, name)
  if number < 0 or number > STYLE_MAX then
    error('invalid style number "'.. number .. '"', 2)
  end
  local buffer = buffer
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
    name = name or buffer.style_name[number],
    number = number,
    apply = apply
  }
  return setmetatable(style, {__concat=style_merge})
end

-- Add the pre-defined lexer styles to the module.
for name, number in pairs(default_styles) do
  M[name] = get_definition(number, name)
end

-- Defines a new style using the given table of style properties.
-- @param name The style name that should be used for the style
-- @param properties The table describing the style
local function define_style(t, name, properties)
  local properties = table_copy(properties)
  local count = 0
  for k, v in pairs(M) do
    if type(v) == 'table' then count = count + 1 end
  end
  local number = STYLE_LASTPREDEFINED + count - count_default_styles + 1
  if (number > STYLE_MAX) then error('Maximum style number exceeded') end
  properties.number = number
  properties.apply = apply
  properties.name = name
  rawset(t, name, properties)
end

-- Set a property if it is set.
local function set_style_property(t, number, value)
  if value ~= nil then t[number] = value end
end

-- Activate Textredux styles in a buffer.
local function activate_styles()
  if not buffer._textredux then return end
  for k, v in pairs(M) do
    if type(v) == 'table' then
      if v.number > STYLE_LASTPREDEFINED then
        set_style_property(buffer.style_size, v.number, v.size)
        set_style_property(buffer.style_bold, v.number, v.bold)
        set_style_property(buffer.style_italic, v.number, v.italic)
        set_style_property(buffer.style_underline, v.number, v.underline)
        set_style_property(buffer.style_fore, v.number, string_to_color(v.fore))
        set_style_property(buffer.style_back, v.number, string_to_color(v.back))
        set_style_property(buffer.style_eol_filled, v.number, v.eolfilled)
        set_style_property(buffer.style_character_set, v.number, v.characterset)
        set_style_property(buffer.style_case, v.number, v.case)
        set_style_property(buffer.style_visible, v.number, v.visible)
        set_style_property(buffer.style_changeable, v.number, v.changeable)
        set_style_property(buffer.style_hot_spot, v.number, v.hotspot)
        set_style_property(buffer.style_font, v.number, v.font)
      end
    end
  end
end

-- Ensure Textredux styles are defined after switching buffers or views.
events.connect(events.BUFFER_AFTER_SWITCH, activate_styles)
events.connect(events.VIEW_NEW, activate_styles)
events.connect(events.VIEW_AFTER_SWITCH, activate_styles)

setmetatable(M, {__newindex=define_style, __concat=style_merge})

return M
