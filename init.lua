--[[-
The TextRedux module offers a set of text based replacement interfaces for
Textadept.

It currently contains the following modules:

- @{_M.textredux.fs}. Contains text based interfaces for file io operations, i.e.
open file, save file as well as snapopen functionality.
- @{_M.textredux.buffer_list}. A text based buffer list replacement, which in
addition to being text based also offers an easy way to close buffers directly
from the list.
- @{_M.textredux.hijack}. Hijacks Textadept, replacing as much functionality as it
can with text based counterparts. In addition to injecting the above modules in
the menu and key bindings, it also replaces the traditional filtered list with
a TextUI list for a number of operations.

## How to use it

TextRedux depends on the TextUI module, and thus you need to install that along
with the TextRedux module itself. Download and install both modules in your
`.textadept/modules/` directory.

Having installed it, there are two ways you can use TextRedux.

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

As the name suggest, TextRedux has now hijacked your environment. All your regular
key bindings, as well as the menu etc. should now use TextRedux where applicable.

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
  gui = require 'textredux.gui',
}

return M
