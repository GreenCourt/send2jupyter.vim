let s:cpo = &cpo
set cpo&vim

vnoremap <buffer><silent> <CR> :call send2jupyter#send()<CR>

let &cpo = s:cpo
unlet s:cpo
