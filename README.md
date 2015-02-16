# vim-debug
convenience layer for pyclewn to overcome some drawbacks. not to be confused with @jaredly's vim-debug, which is much more sophisticated ;)

If you don't know about vdebug, you most definitely should check it out at https://github.com/joonty/vdebug before considering this plugin!

## Motivation

I tried to use pyclewn for simple python pdb debugging and I was amazed how cumbersome its usage is. Just to name a few: a breakpoint is identified by a number which you have to specify whenever you mean to edit, enable/disable or remove it. There is no way to watch variables/expressions. And breakpoints just vanish when pyclewn is restarted.

## Features

Everything you can do with pyclewn, plus

### Breakpoints

- single breakpoint per line
- identify breakpoint by (cursor) position
- single command to create/change/remove breakpoints
- persistence
 - reuses breakpoints on debug startup
 - you may save/load breakpoints to/from file
 - restores breakpoints at perfectly matching lines

### Watch

- add to/remove from watch (simple memory)
- print watch on demand
- persistence
 - along with breakpoints

### Console

Actually, it's no interactive console in the usual sense, but an insert mode keymap that submits entire lines as if written on the command line with `C ...`. Insert mode is never closed, so you can undo everything in an instant once you are done. (reference config maps this to `<c-cr>`)

## Demo

TODO, a lot changed since the last demo

## Getting Started

- get pyclewn
- add this plugin to your vimfiles
 - you might want to check out neobundle at https://github.com/Shougo/neobundle.vim
- add reference config from .vimrc to your config
- start debugger using `<leader>dr`
- try every keymap once

## Notes

- when pyclewn terminates on its own, you will have to call `:DebugStop` before calling `:DebugStart` again

## Documentation

In order of detail

**`debug#dummy()`**

This plugin is entirely in autoload. Call this function to force load it. Until then vim won't recognize this plugin's commands.

**`:DebugStart ...`**

By default runs `Pyclewn ...`, initializes all variables and restores breakpoints.

**`:DebugStop ...`**

By default runs `C import sys; sys.exit(1)`.

**`:DebugBp [at [file]:lineNo[:line]] [range [file]:lineNo[:line] [file]:lineNo[:line]] [temp] [if <condition>] [enable] [disable] [ignore <n>]`**

I think this command is self explanatory with the following exceptions:
- position of arguments don't matter
- arguments containing spaces shall be enclosed by `""`
- either `at` or `range`
- if `line` is specified, tries to find a perfectly matching line close to `lineNo`
- without any arguments (except `at` and `range`)
 - if `at`: create default breakpoint or remove existing breakpoint
 - if `range`: remove all breakpoints in range

**`debug#toggleEnabled(bp)`**

Use this in conjunction with `debug#here()` or `debug#there(file, lineNo)`.

**`:DebugWatch ...` or `:DebugWatch start [stop]`**

Either adds the given watch expression or removes all watch expressions between index start and index stop (included).

**`debug#printWatch()`**

Invokes watch print.

**`debug#save()` and `debug#load()`**

Saves/Loads breakpoints and watch to/from `.vimdebug`.

**`debug#watch(what)`**

Adds the given watch expression.

**`debug#clearWatch(start, stop)`**

Removes all watch expressions between index start and index stop (included).

**`debug#here()` and `debug#there(file, lineNo)`**

Returns the breakpoint at the cursor or specified position. Or `g:debug#nobp` if there is none.

**`debug#clearTemps()`**

Temporary breakpoints are deleted automatically on next break and this plugin can't figure out if they are still alive after `:Ccontinue` or `:Creturn`. Therefore temporary breakpoints are kept in memory until you decide to clear them. Once cleared, you may create new breakpoints on top of existing temporary breakpoints. If temporary breakpoints are already dead, every attempt to change them will fail.

**`g:debug#running`**

Indicates whether `:DebugStart` (false) or `:DebugStop` (true) is expected. `:DebugStart` won't do anything if `g:debug#running` and the inverse applies to `:DebugStop`.

**breakpoint**

A breakpoint is represented by a dictionary. You may write to it but beware that this could have unexpected consequences.

**`g:debug#bps`**
A collection (dictionary) of breakpoints (dictionaries). Key: 'file:lineNo'.

**`g:debug#nobp`**

This is just an empty dictionary and used as invalid breakpoint. For example `debug#here` returns this value to indicate that there is no breakpoint.

**`g:debug#watch`**

A list of strings. You may modify this list as much as you like.

**`g:debug#temps`**

A collection of temporary breakpoints similar to `g:debug#bps`. See `debug#clearTemps()`

**`g:debug#opts`**

This dictionary may be used to change the behaviour of executing functions. If you want to, please check out the default functions at the top of autoload/debug.vim

**`g:debug#count`**

Autoincrementing id for breakpoints. read-only unless you have good reason to!

### Some extra

**`debug#esplit(x)` and `debug#ejoin(items)`**

Suppose you want to supply arguments containing white space to some command. For instance `:Command "arg with space" argwithoutspace`. Then you need to split apart the arguments which is not an easy task using vim's string functions. `debug#esplit` does this, and it removes the quotes. `debug#ejoin` on the other hand wraps each item in `""` when necessary and joins them together.

