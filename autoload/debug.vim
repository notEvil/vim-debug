

" TYPES
fun! s:nofun()
endfun
let s:nofu = function('s:nofun')

let g:debug#nobp = {}


" INIT
fun! debug#dummy() " force loading this module
endfun

fun! s:init()
  let g:debug#opts = extend({
  \ 'startF': s:nofu,
  \ 'stopF': s:nofu,
  \ 'commandF': s:nofu,
  \ 'putBpF': s:nofu,
  \ 'removeBpF': s:nofu,
  \ 'changeBpConditionF': s:nofu,
  \ 'setBpEnabledF': s:nofu,
  \ 'setBpIgnoreF': s:nofu,
  \ 'printF': s:nofu
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


" MAIN HELPER
fun! s:id(file, lineNo)
  return a:file.':'.a:lineNo
endfun

fun! s:createBp(file, lineNo, condition, temp)
  return {
  \ 'id': s:id(a:file, a:lineNo),
  \ 'count': g:debug#count,
  \ 'file': a:file,
  \ 'lineNo': a:lineNo,
  \ 'line': s:getline(a:file, a:lineNo),
  \ 'condition': a:condition,
  \ 'temp': a:temp,
  \ 'enabled': 1
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
      if bp.condition != ''
        call add(r, '3 '.bp.condition)
      endif
      if bp.temp
        call add(r, '4 ')
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
      let bp = s:createBp(file, y, '', 0)
    elseif x == '2'
      let bp.line = y
    elseif x == '3'
      let bp.condition = y
    elseif x == '4'
      let bp.temp = 1
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

fun! s:removeBp(bp)
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

fun! s:here()
  return [expand('%:p'), line('.')]
endfun

fun! s:funNotSet(name)
  echoerr 'g:debug#opts.'.a:name.' not set yet'
endfun


" MAIN
fun! s:start(args)
  if g:debug#running
    return 0
  endif
  let StartF = g:debug#opts.startF
  if StartF == s:nofu
    call s:funNotSet('startF')
    return -1
  endif
  let r = StartF(a:args)
  let g:debug#running = 1
  let bps = values(g:debug#bps)
  let g:debug#bps = {}
  let g:debug#count = 1
  let g:debug#temps = {}
  call s:restore(bps)
  " WARN: create globals __tryeval__ and __debugprint__. might become an issue
  call s:command("exec 'def __tryeval__(x,l,g):\\n try: return eval(x,l,g)\\n except: return \"\"\\n__builtins__[\"__tryeval__\"]=__tryeval__;del __tryeval__'")
  call s:command("exec 'def __debugprint__(x,l,g):\\n print \"\\\\\\n\".join(\"{}: {}: {}\".format(i,y,__tryeval__(y,l,g)) for i,y in enumerate(x))\\n__builtins__[\"__debugprint__\"]=__debugprint__;del __debugprint__'")
  "too long
  "call s:command("exec 'def __debugprint__(x,l,g):\\n def tryeval(x,l,g):\\n  try: return eval(x,l,g)\\n  except: return \"\"\\n format=\"{{{}}}: {{}}: {{}}\".format(len(str(len(x)-1)))\\n print \"\\n\".join(format.format(i,y,tryeval(y,l,g)) for i,y in enumerate(x))'")
  return r
endfun

fun! s:stop(args)
  if !g:debug#running
    return 0
  endif
  let StopF = g:debug#opts.stopF
  if StopF == s:nofu
    call s:funNotSet('stopF')
    return -1
  endif
  let r = StopF(a:args)
  let g:debug#running = 0
  return r
endfun

fun! s:command(command)
  let CommandF = g:debug#opts.commandF
  if CommandF == s:nofu
    call s:funNotSet('commandF')
    return -1
  endif
  return CommandF(a:command)
endfun

" main bp function
fun! s:putThere(file, lineNo, condition, temp)
  let bp = debug#there(a:file, a:lineNo)
  if bp != g:debug#nobp
    if bp.temp != a:temp
      call s:remove(bp) " simply remove and put again afterwards
    else
      return s:changeCondition(bp, a:condition) " change
    endif
  endif
  let PutBpF = g:debug#opts.putBpF
  if PutBpF == s:nofu
    call s:funNotSet('putBpF')
    return -1
  endif
  let bp = s:createBp(a:file, a:lineNo, a:condition, a:temp)
  let r = PutBpF(bp)
  call s:addBp(bp)
  return r
endfun

fun! s:remove(bp)
  let RemoveBpF = g:debug#opts.removeBpF
  if RemoveBpF == s:nofu
    call s:funNotSet('removeBpF')
    return -1
  endif
  let r = RemoveBpF(a:bp)
  call s:removeBp(a:bp)
  return r
endfun

fun! s:changeCondition(bp, condition)
  if a:bp.condition == a:condition
    return 0
  endif
  let ChangeBpConditionF = g:debug#opts.changeBpConditionF
  if ChangeBpConditionF == s:nofu
    call s:funNotSet('changeBpConditionF')
    return -1
  endif
  let r = ChangeBpConditionF(a:bp, a:condition)
  let a:bp.condition = a:condition
  return r
endfun

fun! s:setEnabled(bp, enabled)
  if a:bp.enabled == a:enabled
    return 0
  endif
  let SetBpEnabledF = g:debug#opts.setBpEnabledF
  if SetBpEnabledF == s:nofu
    call s:funNotSet('setBpEnabledF')
    return -1
  endif
  let r = SetBpEnabledF(a:bp, a:enabled)
  let a:bp.enabled = a:enabled
  return r
endfun

fun! s:setIgnore(bp, ignore)
  let SetBpIgnoreF = g:debug#opts.setBpIgnoreF
  if SetBpIgnoreF == s:nofu
    call s:funNotSet('setBpIgnoreF')
    return -1
  endif
  let r = SetBpIgnoreF(a:bp, a:ignore)
endfun

fun! s:print(x, pretty)
  let PrintF = g:debug#opts.printF
  if PrintF == s:nofu
    call s:funNotSet('printF')
    return -1
  endif
  return PrintF(a:x, a:pretty)
endfun

fun! s:restore(bps)
  for bp in a:bps
    call s:putThere(bp.file, s:findline(bp.file, bp.lineNo, bp.line), bp.condition, bp.temp)
    if !bp.enabled
      call s:setEnabled(debug#there(bp.file, bp.lineNo), 0)
    endif
  endfor
endfun


" INTERFACE
fun! s:parseDebugStart(arg)
  call s:start(split(a:arg, ' '))
endfun

command! -nargs=* DebugStart call s:parseDebugStart(<q-args>)

fun! s:parseDebugStop(arg)
  call s:stop(split(a:arg, ' '))
endfun

command! -nargs=* DebugStop call s:parseDebugStop(<q-args>)


fun! debug#here()
  let here = s:here()
  return debug#there(here[0], here[1])
endfun

fun! debug#there(file, lineNo)
  let id = s:id(a:file, a:lineNo)
  if !has_key(g:debug#bps, id)
    return g:debug#nobp
  endif
  return g:debug#bps[id]
endfun

fun! debug#toggleHere(temp)
  let here = s:here()
  return debug#toggleThere(here[0], here[1], a:temp)
endfun

fun! debug#toggleThere(file, lineNo, temp)
  let bp = debug#there(a:file, a:lineNo)
  if bp == g:debug#nobp
    return s:putThere(a:file, a:lineNo, '', a:temp)
  endif
  return s:remove(bp)
endfun

fun! debug#getRecommends()
  let here = s:here()
  return here[0].' '.here[1].' 0'
endfun

fun! s:parseDebugBp(arg)
  let t = split(a:arg, ' ') " also strips a:arg in the process
  call s:putThere(t[0], t[1], join(t[3:]), t[2])
endfun

" file lineNo temp condition...
command! -nargs=1 DebugBp call s:parseDebugBp(<q-args>)

fun! debug#toggleEnabled(bp)
  if a:bp == g:debug#nobp
    return 0
  endif
  return s:setEnabled(a:bp, 1 - a:bp.enabled)
endfun

fun! debug#setIgnore(bp, ignore)
  if a:bp == g:debug#nobp
    return 0
  endif
  return s:setIgnore(a:bp, a:ignore)
endfun

command! -nargs=* DebugBpIgnore call debug#setIgnore(debug#here(), str2nr(<q-args>))

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
  return s:command(join(r, ''))
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


