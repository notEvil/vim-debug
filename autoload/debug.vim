

" TYPES
fun! s:nofun()
endfun
let s:nofu = function('s:nofun')

let g:debug#nobp = {}


" INIT
fun! debug#dummy() " force loading this module
endfun

fun! s:Start(args)
  exe 'Pyclewn pdb '.escape(debug#ejoin(a:args, ' '), '"')
  sleep 100m
  sleep 100m
  return 0
endfun
fun! s:Stop(args)
  C import sys; sys.exit(1)
  return 0
endfun
fun! s:Cmd(cmd)
  exe 'C '.escape(a:cmd, '"')
  return 0
endfun
fun! s:PutBp(bp)
  exe 'C'.(a:bp.temp ? 't' : '').'break '.a:bp.file.':'.a:bp.lineNo.', '.a:bp.if
  return 0
endfun
fun! s:RmBp(bp)
  exe 'Cclear '.a:bp.file.':'.a:bp.lineNo
  return 0
endfun
fun! s:SetBpIf(bp, if)
  exe 'Ccondition '.a:bp.count.' '.a:if
  return 0
endfun
fun! s:SetBpIgnore(bp, ignore)
  exe 'Cignore '.a:bp.count.' '.a:ignore
  return 0
endfun
fun! s:SetBpEnabled(bp, enabled)
  exe 'C'.(a:enabled ? 'enable' : 'disable').' '.a:bp.count
  return 0
endfun
fun! s:Print(x, pretty)
  exe 'Cp'.(a:pretty ? 'p' : '').' '.a:x
  return 0
endfun

fun! s:init()
  let g:debug#opts = extend({
  \ 'startF': function('s:Start'),
  \ 'stopF': function('s:Stop'),
  \ 'cmdF': function('s:Cmd'),
  \ 'putBpF': function('s:PutBp'),
  \ 'rmBpF': function('s:RmBp'),
  \ 'setBpIfF': function('s:SetBpIf'),
  \ 'setBpIgnoreF': function('s:SetBpIgnore'),
  \ 'setBpEnabledF': function('s:SetBpEnabled'),
  \ 'printF': function('s:Print')
  \ }, (exists('g:debug#opts') ? g:debug#opts : {}))
  if !exists('g:debug#bps')
    let g:debug#bps = {}
  endif
  if !exists('g:debug#watch')
    let g:debug#watch = []
  endif
  if !exists('g:debug#running')
    let g:debug#running = 0
  endif
endfun

call s:init()


" HELPER
fun! s:strip(x)
  return substitute(a:x, '(^\s+)|(\s+$)', '', 'g')
endfun

fun! s:getline(file, lineNo)
  let current = expand('%:p')
  if a:file != current
    let buf = bufnr('%')
    exec 'hide view '.a:file
  endif
  call cursor(a:lineNo, 1)
  while 1
    let [l, c] = searchpos('\v\S', 'cnW')
    let r = getline(l)
    if strpart(r, c - 1, 1) == '#'
      call cursor(l + 1, 1)
      continue
    endif
    break
  endwhile
  if a:file != current
    exec 'buffer '.buf
  endif
  return r
endfun

fun! s:findline(file, lineNo, line)
  let current = expand('%:p')
  if a:file != current
    let buf = bufnr('%')
    exec 'hide view '.a:file
  endif
  call cursor(a:lineNo, 1)
  let pattern = '\V\^'.escape(a:line, '\').'\$'
  let l1 = search(pattern, 'cnW')
  let l2 = search(pattern, 'bcnW')
  if l1 == 0
    if l2 == 0
      let r = a:lineNo
    else
      let r = l2
    endif
  else
    if l2 == 0
      let r = l1
    else
      let r = abs(l1-a:lineNo) <= abs(l2-a:lineNo) ? l1 : l2
    endif
  endif
  if a:file != current
    exec 'buffer '.buf
  endif
  return r
endfun

fun! s:parseAt(at)
  let items = debug#esplit(a:at, ':', 1)
  let l = len(items)
  if l < 2
    echoerr 'syntax error, expected file:lineNo[:line]'
  endif
  let file = items[0] == '' ? expand('%:p') : items[0]
  let lineNo = str2nr(items[1])
  if 2 < l
    let lineNo = s:findline(file, lineNo, join(items[2:], ':'))
  endif
  return [file, lineNo]
endfun

fun! s:return(a, b)
  if a:a < a:b
    return a:a
  endif
  return a:b
endfun


" MAIN HELPER
fun! s:id(file, lineNo)
  return a:file.':'.a:lineNo
endfun

fun! s:createBp(file, lineNo, temp, if, enabled)
  return {
  \ 'id': s:id(a:file, a:lineNo),
  \ 'count': g:debug#count,
  \ 'file': a:file,
  \ 'lineNo': a:lineNo,
  \ 'line': s:getline(a:file, a:lineNo),
  \ 'temp': a:temp,
  \ 'if': a:if,
  \ 'enabled': a:enabled
  \ }
endfun

fun! s:serialize(bps, watch)
  let r = []
  let byFile = {}
  for bp in values(a:bps)
    if !has_key(byFile, bp.file)
      let byFile[bp.file] = []
    endif
    call add(byFile[bp.file], bp)
  endfor
  for [file, bps] in items(byFile)
    call add(r, '0 '.file)
    for bp in bps
      call add(r, '1 '.bp.lineNo)
      call add(r, '2 '.bp.line)
      if bp.temp
        call add(r, '3 ')
      endif
      if bp.if != ''
        call add(r, '4 '.bp.if)
      endif
      if !bp.enabled
        call add(r, '5 ')
      endif
    endfor
  endfor
  for watch in a:watch
    call add(r, '6 '.watch)
  endfor
  return r
endfun

fun! s:deserialize(lines)
  let bps = []
  let watch = []
  let bp = g:debug#nobp
  for line in a:lines
    let line = s:strip(line)
    if line == ''
      continue
    endif
    let idx = stridx(line, ' ')
    let x = strpart(line, 0, idx)
    let y = strpart(line, idx + 1)
    if (x == '0' || x == '1') && bp != g:debug#nobp
      call add(bps, bp)
    endif
    if x == '0'
      let file = y
    elseif x == '1'
      let bp = s:createBp(file, str2nr(y), 0, '', 1)
    elseif x == '2'
      let bp.line = y
    elseif x == '3'
      let bp.temp = 1
    elseif x == '4'
      let bp.if = y
    elseif x == '5'
      let bp.enabled = 0
    elseif x == '6'
      call add(watch, y)
    endif
  endfor
  if bp != g:debug#nobp
    call add(bps, bp)
  endif
  return [bps, watch]
endfun

fun! s:addBp(bp)
  let g:debug#bps[a:bp.id] = a:bp
  let g:debug#count += 1
  if a:bp.temp
    let g:debug#temps[a:bp.id] = a:bp
  endif
endfun

fun! s:_removeBp(bp)
  unlet g:debug#bps[a:bp.id]
  if a:bp.temp && has_key(g:debug#temps, a:bp.id)
    unlet g:debug#temps[a:bp.id]
  endif
endfun

fun! s:clearTemps()
  for id in keys(g:debug#temps)
    unlet g:debug#bps[id]
  endfor
  let g:debug#temps = {}
endfun

fun! s:funNotSet(name)
  echoerr 'g:debug#opts.'.a:name.' not set yet'
  return -1
endfun


" MAIN
fun! s:start(args)
  if g:debug#running
    return 0
  endif
  let StartF = g:debug#opts.startF
  if StartF == s:nofu
    return s:funNotSet('startF')
  endif
  let r = StartF(a:args)
  let g:debug#running = 1
  let bps = values(g:debug#bps)
  let g:debug#bps = {}
  let g:debug#count = 1
  let g:debug#temps = {}
  let r = s:return(r, s:restore(bps))
  " WARN: create globals __tryeval__ and __debugprint__. might become an issue
  let r = s:return(r, s:cmd("exec 'def __tryeval__(x,l,g):\\n try: return eval(x,l,g)\\n except: return \"\"\\n__builtins__[\"__tryeval__\"]=__tryeval__;del __tryeval__'"))
  let r = s:return(r, s:cmd("exec 'def __debugprint__(x,l,g):\\n print \"\\\\\\n\".join(\"{}: {}: {}\".format(i,y,__tryeval__(y,l,g)) for i,y in enumerate(x))\\n__builtins__[\"__debugprint__\"]=__debugprint__;del __debugprint__'"))
  "too long
  "call s:cmd("exec 'def __debugprint__(x,l,g):\\n def tryeval(x,l,g):\\n  try: return eval(x,l,g)\\n  except: return \"\"\\n format=\"{{{}}}: {{}}: {{}}\".format(len(str(len(x)-1)))\\n print \"\\n\".join(format.format(i,y,tryeval(y,l,g)) for i,y in enumerate(x))'")
  return r
endfun

fun! s:stop(args)
  if !g:debug#running
    return 0
  endif
  let StopF = g:debug#opts.stopF
  if StopF == s:nofu
    return s:funNotSet('stopF')
  endif
  let r = StopF(a:args)
  let g:debug#running = 0
  return r
endfun

fun! s:cmd(cmd)
  let CmdF = g:debug#opts.cmdF
  if CmdF == s:nofu
    return s:funNotSet('cmdF')
  endif
  return CmdF(a:cmd)
endfun

fun! s:putBp(bp)
  let PutBpF = g:debug#opts.putBpF
  if PutBpF == s:nofu
    return s:funNotSet('putBpF')
  endif
  let r = PutBpF(a:bp)
  call s:addBp(a:bp)
  if !a:bp.enabled
    let a:bp.enabled = 1
    let r = s:return(r, s:setEnabled(a:bp, 0))
  endif
  return r
endfun

fun! s:changeBp(bp, if, enabled)
  return s:return(s:setIf(a:bp, a:if), s:setEnabled(a:bp, a:enabled))
endfun

fun! s:removeBp(bp)
  let RmBpF = g:debug#opts.rmBpF
  if RmBpF == s:nofu
    return s:funNotSet('rmBpF')
  endif
  let r = RmBpF(a:bp)
  call s:_removeBp(a:bp)
  return r
endfun

fun! s:setIf(bp, if)
  if a:bp.if == a:if
    return 0
  endif
  let SetBpIfF = g:debug#opts.setBpIfF
  if SetBpIfF == s:nofu
    return s:funNotSet('setBpIfF')
  endif
  let r = SetBpIfF(a:bp, a:if)
  let a:bp.if = a:if
  return r
endfun

fun! s:setEnabled(bp, enabled)
  if a:bp.enabled == a:enabled
    return 0
  endif
  let SetBpEnabledF = g:debug#opts.setBpEnabledF
  if SetBpEnabledF == s:nofu
    return s:funNotSet('setBpEnabledF')
  endif
  let r = SetBpEnabledF(a:bp, a:enabled)
  let a:bp.enabled = a:enabled
  return r
endfun

fun! s:setIgnore(bp, ignore)
  let SetBpIgnoreF = g:debug#opts.setBpIgnoreF
  if SetBpIgnoreF == s:nofu
    return s:funNotSet('setBpIgnoreF')
  endif
  return SetBpIgnoreF(a:bp, a:ignore)
endfun

fun! s:print(x, pretty)
  let PrintF = g:debug#opts.printF
  if PrintF == s:nofu
    return s:funNotSet('printF')
  endif
  return PrintF(a:x, a:pretty)
endfun

fun! s:restore(bps)
  let r = 0
  for bp in a:bps
    let r = s:return(r, s:putBp(s:createBp(bp.file, s:findline(bp.file, bp.lineNo, bp.line), bp.temp, bp.if, bp.enabled)))
  endfor
  return r
endfun


" INTERFACE
fun! debug#ejoin(items, by)
  let r = []
  for item in a:items
    if stridx(item, ' ') != -1
      call add(r, '"'.item.'"')
    else
      call add(r, item)
    endif
  endfor
  return join(r, a:by)
endfun

fun! debug#esplit(x, by, ...)
  let keepempty = 0 < a:0 ? a:1 : 0
  let r = []
  let items = split(a:x, a:by, 1) " naive split
  let escaped = 0
  for item in items
    if escaped " inside escaped item
      if match(item, '\v(^|[^\\])"$') != -1 " end of escaped item
	let nItem .= a:by.strpart(item, 0, strlen(item)-1) " remove \" (without \)
	call add(r, nItem)
	let escaped = 0
      else
        let nItem .= a:by.item
      endif
    else
      if !keepempty && strlen(item) == 0 " skip empty items
	continue
      endif
      if match(item, '\v^"') != -1 " start of escaped item
	if match(item, '\v[^\\]"') != -1 " end of escaped item
	  call add(r, strpart(item, 1, strlen(item)-2)) " remove \" (without \)
        else " incomplete escaped item
	  let nItem = strpart(item, 1) " remove \" (without \)
	  let escaped = 1
	endif
      else " unescaped item
	call add(r, item)
      endif
    endif
  endfor
  if escaped " end of escaped item not found yet
    let items = split(nItem, a:by)
    let items[0] = '"'.items[0]
    call extend(r, items)
  endif
  return r
endfun


fun! s:parseDebugStart(arg)
  call s:start(debug#esplit(a:arg, ' '))
endfun

command! -nargs=* DebugStart call s:parseDebugStart(<q-args>)

fun! s:parseDebugStop(arg)
  call s:stop(debug#esplit(a:arg, ' '))
endfun

command! -nargs=* DebugStop call s:parseDebugStop(<q-args>)


fun! debug#here()
  return debug#there(expand('%:p'), line('.'))
endfun

fun! debug#there(file, lineNo)
  return get(g:debug#bps, s:id(a:file, a:lineNo), g:debug#nobp)
endfun

fun! s:parseDebugBp(arg)
  let items = debug#esplit(a:arg, ' ')
  let ignored = []
  let args = {}
  let i = 0
  while i < len(items) " parse into args
    let item = items[i]
    if item == 'at'
      let i += 1
      let args['at'] = s:parseAt(items[i])
    elseif item == 'range'
      let i += 2
      let args['range'] = [s:parseAt(items[i-1]), s:parseAt(items[i])]
    elseif item == 'temp'
      let args['temp'] = 1
    elseif item == 'if'
      let i += 1
      let args['if'] = items[i]
    elseif item == 'enable'
      let args['enable'] = 1
    elseif item == 'disable'
      let args['disable'] = 1
    elseif item == 'ignore'
      let i += 1
      let args['ignore'] = str2nr(items[i])
    else
      call add(ignored, item)
    endif
    let i += 1
  endwhile
  let args['rm'] = !(has_key(args, 'temp') || has_key(args, 'if') || has_key(args, 'enable') || has_key(args, 'disable') || has_key(args, 'ignore')) " not perfect because not specifying temp could mean untempify this bp
  if has_key(args, 'at')
    let bp = debug#there(args.at[0], args.at[1])
    if bp == g:debug#nobp
      let bp = s:createBp(args.at[0], args.at[1], get(args, 'temp', 0), get(args, 'if', ''), !get(args, 'disable', 0))
      call s:putBp(bp)
      if has_key(args, 'ignore')
	call s:setIgnore(bp, args.ignore)
      endif
      return
    endif
    return s:_parseDebugBp(bp, args)
  elseif has_key(args, 'range')
    let [a, b] = args.range " unpack from, to
    let file = a[0] " get file path
    let [x, y] = [a[1], b[1]] " unpack from line, to line
    for bp in values(g:debug#bps)
      if (bp.file != file) || (bp.lineNo < x) || (y < bp.lineNo)
	continue
      endif
      call s:_parseDebugBp(bp, args)
    endfor
  endif
  if len(ignored) != 0
    echom 'ignored: '.ignored
  endif
endfun

fun! s:_parseDebugBp(bp, args)
  if a:args['rm']
    call s:removeBp(a:bp)
    return
  endif
  let if = get(a:args, 'if', a:bp.if)
  let enabled = get(a:args, 'enable', !get(a:args, 'disable', !a:bp.enabled))
  if get(a:args, 'temp', a:bp.temp) != a:bp.temp
    call s:removeBp(a:bp)
    call s:putBp(s:createBp(a:bp.file, a:bp.lineNo, a:args.temp, if, enabled))
    return
  endif
  call s:changeBp(a:bp, if, enabled)
  if has_key(a:args, 'ignore')
    call s:setIgnore(a:bp, a:args.ignore)
  endif
endfun

" main command for breakpoints
command! -nargs=1 -range DebugBp call s:parseDebugBp(<q-args>)


fun! debug#toggleEnabled(bp)
  if a:bp == g:debug#nobp
    return 0
  endif
  return s:setEnabled(a:bp, 1 - a:bp.enabled)
endfun

fun! debug#clearTemps()
  call s:clearTemps()
endfun


fun! debug#watch(what)
  call add(g:debug#watch, s:strip(a:what))
endfun

fun! debug#clearWatch(start, stop)
  unlet g:debug#watch[a:start : a:stop]
endfun

fun! s:parseDebugWatch(arg)
  let arg = s:strip(a:arg)
  if match(arg, '\v^\d+(\s+\d+)?$') != -1
    let items = split(arg)
    let start = items[0]
    let stop = (1 < len(items) ? items[1] : start)
    call debug#clearWatch(start, stop)
    return
  endif
  call debug#watch(arg)
endfun

command! -nargs=1 DebugWatch call s:parseDebugWatch(<q-args>)

fun! debug#printWatch()
  if empty(g:debug#watch)
    return 0
  endif
  "let r = ["exec 'def __tryeval__(x,l,g):\\n try: return eval(x,l,g)\\n except: return \"\"';", "print '\\n'.join(['{:", float2nr(ceil(log10(len(g:debug#watch)+1))), "}: {}: {}'.format(i,x,__tryeval__(x,locals(),globals())) for i,x in enumerate(["] ", ']))']
  let r = ['__builtins__["__debugprint__"]([']
  let i = 0
  for item in g:debug#watch
    call add(r, "'".escape(item, "'")."',")
  endfor
  call add(r, '],locals(),globals())')
  "call add(r, '])]); del __tryeval__')
  " WARN: command length might become an issue
  return s:cmd(join(r, ''))
endfun

"fun! debug#printWatch()
  "if empty(g:debug#watch)
    "return 0
  "endif
  "let r = ['{']
  "let i = 0
  "for item in g:debug#watch
    "call add(r, "'".i.': '.item."':")
    "call add(r, item)
    "call add(r, ',')
  "endfor
  "call add(r, '}')
  "return s:print(join(r, ''), 1)
"endfun


fun! debug#save()
  if empty(g:debug#bps) && empty(g:debug#watch)
    return
  endif
  return writefile(s:serialize(g:debug#bps, g:debug#watch), '.vimdebug')
endfun

fun! debug#load()
  if !filereadable('.vimdebug')
    return
  endif
  let [bps, watch] = s:deserialize(readfile('.vimdebug'))
  call s:restore(bps)
  for w in watch
    call debug#watch(w)
  endfor
endfun


