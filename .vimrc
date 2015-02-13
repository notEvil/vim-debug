fun! Start(args)
  exe 'Pyclewn pdb '.join(a:args, ' ')
  sleep 100m
  sleep 100m
endfun
fun! Stop(args)
  C import sys; sys.exit(1)
endfun
fun! Command(command)
  exe 'C '.escape(a:command, '"')
endfun
fun! PutBp(bp)
  exe 'C'.(a:bp.temp ? 't' : '').'break '.a:bp.file.':'.a:bp.line.', '.a:bp.condition
endfun
fun! RemoveBp(bp)
  exe 'Cclear '.a:bp.file.':'.a:bp.line
endfun
fun! ChangeBpCondition(bp, condition)
  exe 'Ccondition '.a:bp.count.' '.a:condition
endfun
fun! SetBpEnabled(bp, enabled)
  exe 'C'.(a:enabled ? 'enable' : 'disable').' '.a:bp.count
endfun
fun! SetBpIgnore(bp, ignore)
  exe 'Cignore '.a:bp.count.' '.a:ignore
endfun
fun! Print(x, pretty)
  exe 'Cp'.(a:pretty ? 'p' : '').' '.a:x
endfun
let g:debug#opts = {
\ 'startF': function('Start'),
\ 'stopF': function('Stop'),
\ 'commandF': function('Command'),
\ 'putBpF': function('PutBp'),
\ 'removeBpF': function('RemoveBp'),
\ 'changeBpConditionF': function('ChangeBpCondition'),
\ 'setBpEnabledF': function('SetBpEnabled'),
\ 'setBpIgnoreF': function('SetBpIgnore'),
\ 'printF': function('Print')
\ }
" without sleep commands might not get executed
nnoremap <leader>dr :call debug#dummy()<cr>:DebugStart <c-r>=expand('%:p')<cr><cr>
nnoremap <leader>dq :DebugStop<cr>
nnoremap <leader>dl :call debug#load()<cr>
nnoremap <leader>ds :call debug#save()<cr>
nnoremap <c-c> :Cinterrupt<cr>
nnoremap <F1> :call debug#printWatch()<cr>
nnoremap <F5> :Cstep<cr>
nnoremap <F6> :Cnext<cr>
nnoremap <F7> :Creturn<cr>:call debug#clearTemps()<cr>
nnoremap <F8> :Ccontinue<cr>:call debug#clearTemps()<cr>
nnoremap <F11> :Cup<cr>
nnoremap <F12> :Cdown<cr>
" breakpoints
nnoremap <leader>d<space> :call debug#toggleHere(0)<cr>
nnoremap <leader>dc :DebugBp <c-r>=debug#getRecommends()<cr> 
nnoremap <leader>dt :call debug#toggleHere(1)<cr>
nnoremap <leader>dd :call debug#toggleHere(1)<cr>:Ccontinue<cr>:call debug#clearTemps()<cr>
nnoremap <leader>de :call debug#toggleEnabled(debug#here())<cr>
nnoremap <leader>di :DebugBpIgnore 
" prints
nnoremap <leader>dp :Cpp <c-r>=expand('<cword>')<cr><cr>
xnoremap <c-cr> ""y:Cpp <c-r>=escape(@", '"')<cr><cr>
inoremap <c-cr> <c-o>on<c-o>:Cpp <c-r>=getline(line('.')-1)<cr><cr><bs>
nnoremap <leader>dw :DebugWatch 
