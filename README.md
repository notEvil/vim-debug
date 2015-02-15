# vim-debug
convenience layer for pyclewn to overcome some drawbacks. not to be confused with @jaredly's vim-debug, which is much more sophisticated ;)

If you don't know about vdebug, you most definitely should check it out at https://github.com/joonty/vdebug before considering this plugin!

Motivation
==========
I tried to use pyclewn for simple python pdb debugging and I was amazed how cumbersome its usage is. Just to name a few: a breakpoint is identified by a number which you have to specify whenever you mean to edit, enable/disable or remove it. There is no way to watch variables/expressions. And breakpoints just vanish when pyclewn is restarted.

Features
========

Everything you can do with pyclewn, plus

Breakpoints
-----------

- single breakpoint per line
- identify breakpoint by (cursor) position
- single command to create/change/remove breakpoints
- persistence
 - reuses breakpoints on debug startup
 - you may save/load breakpoints to/from file
 - restores breakpoints at perfectly matching lines

Watch
-----

- add to/remove from watch (simple memory)
- print watch on demand
- persistence
 - along with breakpoints

Console
-------

Actually, it's no interactive console in the usual sense, but an insert mode keymap that submits entire lines as if written on the command line with `C ...`. Insert mode is never closed, so you can undo everything in an instant once you are done. (reference config maps this to `<c-cr>`)

Demo
====

TODO, a lot changed since

Getting Started
===============

- get pyclewn
- add this plugin to your vimfiles
 - you might want to check out neobundle at https://github.com/Shougo/neobundle.vim
- add reference config from .vimrc to your config
- start debugger using `<leader>dr`
- try every keymap once

Notes
=====

- when pyclewn terminates on its own, you will have to call `:DebugStop` before calling `:DebugStart` again

Documentation
=============

TODO, will be there soon :)

