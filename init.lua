--[[-
The Textredux module allows you to easily create text based interfaces for the
[Textadept](http://foicica.com/textadept/) editor and offers a set of text
based interfaces.

It currently contains the following modules:

- @{textredux.core}. The core module provides basic components to create
  text based interfaces.
- @{textredux.fs}. Contains text based interfaces for file io operations,
  i.e. open file, save file as well as snapopen functionality.
- @{textredux.buffer_list}. A text based buffer list replacement, which in
  addition to being text based also offers an easy way to close buffers
  directly from the list.
- @{textredux.hijack}. Hijacks Textadept, replacing all keyboard shortcuts
  with text based counterparts. Additionally, it replaces the traditional
  filtered list with a Textredux list for a number of operations.

## How to use it

Download and put the Textredux module in your `.textadept/modules/`
directory.

Having installed it, there are two ways you can use Textredux. Note that due to
Textredux re-using colors defined in your theme file, loading Textredux modules
should be wrapped using
[events.INITIALIZED](http://foicica.com/textadept/api/events.html#INITIALIZED).

1) Cherrypick the functionality you want from the different modules by assigning
key bindings to the desired functions. As an example, if you would like to use
the text based file browser and normally opens files using `Ctr-O`, then the
following code in your `init.lua` would do the trick:

    events.connect(events.INITIALIZED, function()
      textredux = require 'textredux'
      keys.co = textredux.fs.open_file
    end)

2) If you can't get enough of text based interfaces and the joy they provide,
then the @{textredux.hijack} module is for you. Simple place this in your
`init.lua`:

    events.connect(events.INITIALIZED, function()
      require 'textredux.hijack'
    end)

As the name suggest, Textredux has now hijacked your environment. All your
regular key bindings should now use Textredux where applicable. Clicking the
menu will open the standard dialogs.

## Customizing

Please see the module documentation for the various modules for configurable
settings.

@author Nils Nordman <nino at nordman.org>
@copyright 2011-2012
@license MIT (see LICENSE)
@module textredux
]]

local M = {
  buffer_list = require 'textredux.buffer_list',
  fs = require 'textredux.fs',
  core = require 'textredux.core',
}

return M
