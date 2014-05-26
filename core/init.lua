-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The Textredux core module allows you to easily create text based interfaces
for the [Textadept](http://foicica.com/textadept/) editor.

It currently consists of the following components:

- A @{textredux.core.buffer} class that supports custom styling, buffer
  specific key bindings, hotspot support and generally makes it easy to
  create a text based interface buffer by taking care of the background
  gruntwork required.

  - A @{textredux.core.style} module that let's you easily define custom
  styles, as well as leveraging the default styles already provided by the
  user's theme.

- A @{textredux.core.indicator} module that provides a convenient way of
  using indicators in your buffers.

- A @{textredux.core.list} class that provides a versatile and extensible
  text based item listing for Textadept, featuring advanced search capabilities
  and styling.

How to use
----------

After installing the Textredux module into your `modules` directory, you can
either do

    textredux.core = require 'textredux.core'

to require and place all the core modules under the M.textredux namespace. You
can also optionally require just the modules that you want by something
similar to

    local reduxstyle = require 'textredux.core.style'
    local reduxbuffer = require 'textredux.core.style'

The examples provide an overview on how to use the various components and their
features, and the documentation for each component provide more in depth details.

@module textredux.core
]]

local M = {
  buffer = require 'textredux.core.buffer',
  style = require 'textredux.core.style',
  list = require 'textredux.core.list',
  indicator = require 'textredux.core.indicator',
}

local line_number_back =
  buffer.style_back[_SCINTILLA.constants.STYLE_LINENUMBER]
local current_line_back = buffer.caret_line_back

--[[-- Sets the margin styles in a Textredux buffer.
Line numbers are hidden by setting them to the background color in the Curses
version and by setting the line number margin to the color used for
highlighting the current line.
]]
function M.set_margin_styles()
  local line_number = 33
  local buffer = buffer
  if buffer._textredux then
    if CURSES then
      buffer.style_fore[line_number] = line_number_back
    else
      buffer.style_fore[line_number] = current_line_back
      buffer.style_back[line_number] = current_line_back
    end
  else
    if not CURSES then
      buffer.style_back[line_number] = current_line_back
    end
  end
end

events.connect(events.BUFFER_AFTER_SWITCH, M.set_margin_styles)
events.connect(events.VIEW_AFTER_SWITCH, M.set_margin_styles)


return M
