-- Copyright 2011-2012 Nils Nordman <nino at nordman.org>
-- Copyright 2012-2014 Robert Gieseke <rob.g@web.de>
-- License: MIT (see LICENSE)

--[[--
The Textredux core module allows you to easily create text based interfaces
for the [Textadept](http://foicica.com/textadept/) editor.

It currently consists of the following components:

- The @{textredux.core.buffer} module that supports custom styling, buffer
  specific key bindings, hotspot support and generally makes it easy to
  create a text based interface buffer by taking care of the background
  gruntwork required.

  - The @{textredux.core.style} module that let's you easily define custom
  styles, as well as leveraging the default styles already provided by the
  user's theme.

- The @{textredux.core.indicator} module that provides a convenient way of
  using indicators in your buffers.

- The @{textredux.core.list} module that provides a versatile and extensible
  text based item listing for Textadept, featuring advanced search capabilities
  and styling.

How to use
----------

After installing the Textredux module into your `modules` directory, you can
either do

    local textredux = require('textredux')
    local reduxlist = textredux.core.list

or you can just the modules that you want by something
similar to

    local reduxstyle = require('textredux.core.style')
    local reduxbuffer = require('textredux.core.style')

The examples provide an overview on how to use the various components and their
features, and the documentation for each component provides more details.

@module textredux.core
]]

local M = {
  buffer = require 'textredux.core.buffer',
  filteredlist = require 'textredux.core.filteredlist',
  style = require 'textredux.core.style',
  list = require 'textredux.core.list',
  indicator = require 'textredux.core.indicator',
}

return M
