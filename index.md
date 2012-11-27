---
layout: default
---

TextRedux is a module for the [TextAdept editor](http://foicica.com/textadept/)
that offers a set of text based replacement interfaces for core TextAdept
functionality. The current version offers:

* A text based file browser. Completely keyboard driven, with powerful searching
  functionality and the ability to seamlessly switch between traditional and
  snapopen (recursive) listings.
* A replacement for the buffer list. In addition to being text based, it also
  provides an easy way of closing buffers.
* A no-holds-barred integration module that automatically integrates all TextRedux
  functionality in the TextAdept editor. No need to configure anything further
  unless you want to - once you've required this you will be using TextRedux.
  In addition to integrating the above modules, it will hook into TextAdept and
  inject text based interfaces whereever it can, (.e.g. theme selection,
  run command, etc.)

## Installation

TextRedux depends on the [TextUI module](https://github.com/rgieseke/textui), which
needs to be installed along with TextRedux. Please see the link for more information
about how to download TextUI.

The TextRedux module itself can be downloaded from the [download page](https://github.com/rgieseke/textredux/downloads).

To install the module, just unpack the module into the `.textadept/modules/textredux`
directory.

## Usage

Having installed the module, there are two ways you can use it.

1) Cherrypick the functionality you want from the different modules by assigning
key bindings to the desired functions. As an example, if you would like to use
the text based file browser and normally opens files using `Ctrl + o`, then the
following code in your `init.lua` would do the trick:

    _M.textredux = require 'textredux'
    keys.co = _M.textredux.fs.open_file

2) If you can't get enough of text based interfaces and the joy they provide,
then the hijack module is for you. Simple place this in your `init.lua`:

    require 'textredux.hijack'

As the name suggest, TextRedux has now hijacked your environment. All your regular
key bindings, as well as the menu etc. should now use TextRedux where applicable.

Regardless of the approach chosen, the
[module documentation](http://nordman.org/textredux/docs/) contains more
in-depth documentation for the various modules, including customization tips.

Also, make sure to take a brief look at the [visual tour](tour.html) for some
quick tips on using TextRedux.

## Code

TextRedux is released under the MIT license (see the LICENSE file in the source
for the full details). The source code is available from [GitHub](https://github.com/rgieseke/textredux). It was written by [Nils Nordman](https://github.com/nilnor) and is now maintained by [Robert Gieseke](https://github.com/rgieseke).

## Contribute

Any feedback, be it patches, feature request or bug reports is most welcome.

If you want to provide patches, the preferred way of doing so would be as a pull
request via GitHub, or as a pull request from some other Git server. Should that
not be an option I'll gladly accept patches through other means as well.

If you have any bug reports or feature requests, please submit these to the
[Github issue tracker](https://github.com/rgieseke/textredux/issues). As with
patches, I'll be happy to recieve these through other means as well.

## Changelog

### 0.3 (2012-11-28)

- Updates for API changes until Textadept 6.
- Don't hijack menu entries, use the default widget when clicking the menus.

### 0.2 (2012-03-08)

- Make ctrl+enter open entries in another view (buffer list / file browser)
- Make buffer list keys configurable
- Handle buffers with nil directories in the buffer list

### 0.1 (2012-01-20)

First public release.
