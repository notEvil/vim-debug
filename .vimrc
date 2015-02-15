nnoremap <leader>dr :call debug#dummy()<cr>:DebugStart "<c-r>=expand('%:p')<cr>"<cr>
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
nnoremap <leader>d<space> :DebugBp at :<c-r>=line('.')<cr><cr>
xnoremap <leader>d<space> :DebugBp range :<c-r>=line("'<")<cr> :<c-r>=line("'>")<cr><cr>
nnoremap <leader>dc :DebugBp at :<c-r>=line('.')<cr> 
xnoremap <leader>dc :DebugBp range :<c-r>=line("'<")<cr> :<c-r>=line("'>")<cr> 
nnoremap <leader>dt :DebugBp temp at :<c-r>=line('.')<cr><cr>
nnoremap <leader>dd :DebugBp temp at :<c-r>=line('.')<cr><cr>:Ccontinue<cr>:call debug#clearTemps()<cr>
nnoremap <leader>de :call debug#toggleEnabled(debug#here())<cr>
xnoremap <leader>de :DebugBp range :<c-r>=line("'<")<cr> :<c-r>=line("'>")<cr> enable<cr>
xnoremap <leader>dd :DebugBp range :<c-r>=line("'<")<cr> :<c-r>=line("'>")<cr> disable<cr>
" prints
nnoremap <leader>dp :Cpp <c-r>=expand('<cword>')<cr><cr>
nnoremap <c-cr> <cr>:C <c-r>=getline(line('.')-1)<cr><cr>
xnoremap <c-cr> ""y:Cpp <c-r>=escape(@", '"')<cr><cr>
inoremap <c-cr> <c-o>on<c-o>:Cpp <c-r>=getline(line('.')-1)<cr><cr><bs>
nnoremap <leader>dw :DebugWatch 
