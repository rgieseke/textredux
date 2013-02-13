--[[-
The Textredux module allows you to easily create text based interfaces for the
[Textadept](http://foicica.com/textadept/) editor and offers a set of text
based interfaces.

It currently contains the following modules:

- @{_M.textredux.style}. A module that let's you easily define custom styles,
  as well as leveraging the default styles already provided by the user's
  theme.
- @{_M.textredux.indicator}. A module that provides a convenient way of using
  indicators in your buffers.
- @{_M.textredux.buffer}. A  class that supports custom styling, buffer
  specific key bindings, hotspot support and generally makes it easy to create
  a text based interface buffer by taking care of the background gruntwork
  required.
- @{_M.textredux.list}. A class that provides a versatile and extensible text
  based item listing for Textadept, featuring advanced search capabilities and
  styling.
- @{_M.textredux.fs}. Contains text based interfaces for file io operations,
  i.e. open file, save file as well as snapopen functionality.
- @{_M.textredux.buffer_list}. A text based buffer list replacement, which in
  addition to being text based also offers an easy way to close buffers
  directly from the list.
- @{_M.textredux.hijack}. Hijacks Textadept, replacing all keyboard shortcuts
  with text based counterparts. Additionally, it replaces the traditional
  filtered list with a Textredux list for a number of operations.

## How to use it

Download and install the Textredux module in your `.textadept/modules/`
directory.

Having installed it, there are two ways you can use Textredux.

1) Cherrypick the functionality you want from the different modules by assigning
key bindings to the desired functions. As an example, if you would like to use
the text based file browser and normally opens files using `Ctrl + o`, then the
following code in your `init.lua` would do the trick:

    _M.textredux = require 'textredux'
    keys.co = _M.textredux.fs.open_file

2) If you can't get enough of text based interfaces and the joy they provide,
then the @{_M.textredux.hijack} module is for you. Simple place this in your
`init.lua`:

    require 'textredux.hijack'

As the name suggest, Textredux has now hijacked your environment. All your
regular key bindings should now use Textredux where applicable. Clicking the
menu will open the standard dialogs.

## Customizing

Please see the module documentation for the various modules for configurable
settings.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module _M.textredux
]]

local M = {
  buffer_list = require 'textredux.buffer_list',
  fs = require 'textredux.fs',
  gui = require 'textredux.ui.gui',
  buffer = require 'textredux.ui.buffer',
  list = require 'textredux.ui.list',
  indicator = require 'textredux.ui.indicator',
  style = require 'textredux.ui.style',
}

return M
