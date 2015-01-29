# vim-debug
convenience layer for (py)clewn to overcome some of its drawbacks. not to be confused with @jaredly's vim-debug, which is much more sophisticated ;)

Motivation
==========
I recently tried to use pyclewn for simple python pdb debugging and was amazed how cumbersome its usage is. Just to name a few: Most of the breakpoint related functions take a number to identify the breakpoint. Then there is no watch at all. And breakpoints just vanish when the pyclewn is restarted.

If you don't know about vdebug, you most definitely should check it out at https://github.com/joonty/vdebug before considering this plugin ;)

Features
========

Everything you can do with pyclewn, plus

Breakpoints
-----------

- single breakpoint per line
- identify breakpoint by cursor position
- persistence
 - are reused the next time a debug session starts
 - may be saved to/loaded from file

Watch
-----

- add to/remove from watch (simple memory)
- print watch on demand
- persistence
 - may be saved to/loaded from file

Getting Started
===============

- get pyclewn
- add this plugin to your vimfiles
 - you might want to check out neobundle at https://github.com/Shougo/neobundle.vim
- add reference config from .vimrc to your config
- start debugger using `<leader>dr`
- try every keymap once

Documentation
=============

I'm not too eager to write one ;) But if you tried the plugin and feel the need to get written insights, then create an issue and I will obey.

Demo
====
TODO
