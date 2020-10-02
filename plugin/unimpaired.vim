" unimpaired.vim - Pairs of handy bracket mappings
" Maintainer:   Tim Pope <http://tpo.pe/>
" Version:      2.0
" GetLatestVimScripts: 1590 1 :AutoInstall: unimpaired.vim

if exists("g:loaded_unimpaired") || &cp || v:version < 700
  finish
endif
let g:loaded_unimpaired = 1

let s:maps = []
function! s:map(...) abort
  call add(s:maps, copy(a:000))
endfunction

function! s:maps() abort
  for [mode, head, rhs; rest] in s:maps
    let flags = get(rest, 0, '') . (rhs =~# '^<Plug>' ? '' : '<script>')
    let tail = ''
    let keys = get(g:, mode.'remap', {})
    if type(keys) != type({})
      continue
    endif
    while !empty(head) && len(keys)
      if has_key(keys, head)
        let head = keys[head]
        if empty(head)
          let head = '<skip>'
        endif
        break
      endif
      let tail = matchstr(head, '<[^<>]*>$\|.$') . tail
      let head = substitute(head, '<[^<>]*>$\|.$', '', '')
    endwhile
    if head !=# '<skip>' && empty(maparg(head.tail, mode))
      exe mode.'map' flags head.tail rhs
    endif
  endfor
endfunction

" Section: Next and previous

function! s:MapNextFamily(map,cmd) abort
  let map = '<Plug>unimpaired'.toupper(a:map)
  let cmd = '".(v:count ? v:count : "")."'.a:cmd
  let end = '"<CR>'.(a:cmd ==# 'l' || a:cmd ==# 'c' ? 'zv' : '')
  execute 'nnoremap <silent> '.map.'Previous :<C-U>exe "'.cmd.'previous'.end
  execute 'nnoremap <silent> '.map.'Next     :<C-U>exe "'.cmd.'next'.end
  execute 'nnoremap <silent> '.map.'First    :<C-U>exe "'.cmd.'first'.end
  execute 'nnoremap <silent> '.map.'Last     :<C-U>exe "'.cmd.'last'.end
  call s:map('n', '['.        a:map , map.'Previous')
  call s:map('n', ']'.        a:map , map.'Next')
  call s:map('n', '['.toupper(a:map), map.'First')
  call s:map('n', ']'.toupper(a:map), map.'Last')
  if exists(':'.a:cmd.'nfile')
    execute 'nnoremap <silent> '.map.'PFile :<C-U>exe "'.cmd.'pfile'.end
    execute 'nnoremap <silent> '.map.'NFile :<C-U>exe "'.cmd.'nfile'.end
    call s:map('n', '[<C-'.toupper(a:map).'>', map.'PFile')
    call s:map('n', ']<C-'.toupper(a:map).'>', map.'NFile')
  elseif exists(':p'.a:cmd.'next')
    execute 'nnoremap <silent> '.map.'PPrevious :<C-U>exe "p'.cmd.'previous'.end
    execute 'nnoremap <silent> '.map.'PNext :<C-U>exe "p'.cmd.'next'.end
    call s:map('n', '[<C-'.toupper(a:map).'>', map.'PPrevious')
    call s:map('n', ']<C-'.toupper(a:map).'>', map.'PNext')
  endif
endfunction

call s:MapNextFamily('a','')
call s:MapNextFamily('b','b')
call s:MapNextFamily('l','l')
call s:MapNextFamily('q','c')
call s:MapNextFamily('t','t')

function! s:entries(path) abort
  let path = substitute(a:path,'[\\/]$','','')
  let files = split(glob(path."/.*"),"\n")
  let files += split(glob(path."/*"),"\n")
  call map(files,'substitute(v:val,"[\\/]$","","")')
  call filter(files,'v:val !~# "[\\\\/]\\.\\.\\=$"')

  let filter_suffixes = substitute(escape(&suffixes, '~.*$^'), ',', '$\\|', 'g') .'$'
  call filter(files, 'v:val !~# filter_suffixes')

  return files
endfunction

function! s:FileByOffset(num) abort
  let file = expand('%:p')
  if empty(file)
    let file = getcwd() . '/'
  endif
  let num = a:num
  while num
    let files = s:entries(fnamemodify(file,':h'))
    if a:num < 0
      call reverse(sort(filter(files,'v:val <# file')))
    else
      call sort(filter(files,'v:val ># file'))
    endif
    let temp = get(files,0,'')
    if empty(temp)
      let file = fnamemodify(file,':h')
    else
      let file = temp
      let found = 1
      while isdirectory(file)
        let files = s:entries(file)
        if empty(files)
          let found = 0
          break
        endif
        let file = files[num > 0 ? 0 : -1]
      endwhile
      let num += (num > 0 ? -1 : 1) * found
    endif
  endwhile
  return file
endfunction

function! s:fnameescape(file) abort
  if exists('*fnameescape')
    return fnameescape(a:file)
  else
    return escape(a:file," \t\n*?[{`$\\%#'\"|!<")
  endif
endfunction

nnoremap <silent> <Plug>unimpairedDirectoryNext     :<C-U>edit <C-R>=<SID>fnameescape(fnamemodify(<SID>FileByOffset(v:count1), ':.'))<CR><CR>
nnoremap <silent> <Plug>unimpairedDirectoryPrevious :<C-U>edit <C-R>=<SID>fnameescape(fnamemodify(<SID>FileByOffset(-v:count1), ':.'))<CR><CR>
call s:map('n', ']f', '<Plug>unimpairedDirectoryNext')
call s:map('n', '[f', '<Plug>unimpairedDirectoryPrevious')

" Section: Diff

call s:map('n', '[n', '<Plug>unimpairedContextPrevious')
call s:map('n', ']n', '<Plug>unimpairedContextNext')
call s:map('x', '[n', '<Plug>unimpairedContextPrevious')
call s:map('x', ']n', '<Plug>unimpairedContextNext')
call s:map('o', '[n', '<Plug>unimpairedContextPrevious')
call s:map('o', ']n', '<Plug>unimpairedContextNext')

nnoremap <silent> <Plug>unimpairedContextPrevious :<C-U>call <SID>Context(1)<CR>
nnoremap <silent> <Plug>unimpairedContextNext     :<C-U>call <SID>Context(0)<CR>
xnoremap <silent> <Plug>unimpairedContextPrevious :<C-U>exe 'normal! gv'<Bar>call <SID>Context(1)<CR>
xnoremap <silent> <Plug>unimpairedContextNext     :<C-U>exe 'normal! gv'<Bar>call <SID>Context(0)<CR>
onoremap <silent> <Plug>unimpairedContextPrevious :<C-U>call <SID>ContextMotion(1)<CR>
onoremap <silent> <Plug>unimpairedContextNext     :<C-U>call <SID>ContextMotion(0)<CR>

function! s:Context(reverse) abort
  call search('^\(@@ .* @@\|[<=>|]\{7}[<=>|]\@!\)', a:reverse ? 'bW' : 'W')
endfunction

function! s:ContextMotion(reverse) abort
  if a:reverse
    -
  endif
  call search('^@@ .* @@\|^diff \|^[<=>|]\{7}[<=>|]\@!', 'bWc')
  if getline('.') =~# '^diff '
    let end = search('^diff ', 'Wn') - 1
    if end < 0
      let end = line('$')
    endif
  elseif getline('.') =~# '^@@ '
    let end = search('^@@ .* @@\|^diff ', 'Wn') - 1
    if end < 0
      let end = line('$')
    endif
  elseif getline('.') =~# '^=\{7\}'
    +
    let end = search('^>\{7}>\@!', 'Wnc')
  elseif getline('.') =~# '^[<=>|]\{7\}'
    let end = search('^[<=>|]\{7}[<=>|]\@!', 'Wn') - 1
  else
    return
  endif
  if end > line('.')
    execute 'normal! V'.(end - line('.')).'j'
  elseif end == line('.')
    normal! V
  endif
endfunction

" Section: Line operations

function! s:BlankUp(count) abort
  put!=repeat(nr2char(10), a:count)
  ']+1
  silent! call repeat#set("\<Plug>unimpairedBlankUp", a:count)
endfunction

function! s:BlankDown(count) abort
  put =repeat(nr2char(10), a:count)
  '[-1
  silent! call repeat#set("\<Plug>unimpairedBlankDown", a:count)
endfunction

nnoremap <silent> <Plug>unimpairedBlankUp   :<C-U>call <SID>BlankUp(v:count1)<CR>
nnoremap <silent> <Plug>unimpairedBlankDown :<C-U>call <SID>BlankDown(v:count1)<CR>

call s:map('n', '[<Space>', '<Plug>unimpairedBlankUp')
call s:map('n', ']<Space>', '<Plug>unimpairedBlankDown')

function! s:ExecMove(cmd) abort
  let old_fdm = &foldmethod
  if old_fdm !=# 'manual'
    let &foldmethod = 'manual'
  endif
  normal! m`
  silent! exe a:cmd
  norm! ``
  if old_fdm !=# 'manual'
    let &foldmethod = old_fdm
  endif
endfunction

function! s:Move(cmd, count, map) abort
  call s:ExecMove('move'.a:cmd.a:count)
  silent! call repeat#set("\<Plug>unimpairedMove".a:map, a:count)
endfunction

function! s:MoveSelectionUp(count) abort
  call s:ExecMove("'<,'>move'<--".a:count)
  silent! call repeat#set("\<Plug>unimpairedMoveSelectionUp", a:count)
endfunction

function! s:MoveSelectionDown(count) abort
  call s:ExecMove("'<,'>move'>+".a:count)
  silent! call repeat#set("\<Plug>unimpairedMoveSelectionDown", a:count)
endfunction

nnoremap <silent> <Plug>unimpairedMoveUp            :<C-U>call <SID>Move('--',v:count1,'Up')<CR>
nnoremap <silent> <Plug>unimpairedMoveDown          :<C-U>call <SID>Move('+',v:count1,'Down')<CR>
noremap  <silent> <Plug>unimpairedMoveSelectionUp   :<C-U>call <SID>MoveSelectionUp(v:count1)<CR>
noremap  <silent> <Plug>unimpairedMoveSelectionDown :<C-U>call <SID>MoveSelectionDown(v:count1)<CR>

call s:map('n', '[e', '<Plug>unimpairedMoveUp')
call s:map('n', ']e', '<Plug>unimpairedMoveDown')
call s:map('x', '[e', '<Plug>unimpairedMoveSelectionUp')
call s:map('x', ']e', '<Plug>unimpairedMoveSelectionDown')

" Section: Put

function! s:putline(how, map) abort
  let [body, type] = [getreg(v:register), getregtype(v:register)]
  if type ==# 'V'
    exe 'normal! "'.v:register.a:how
  else
    call setreg(v:register, body, 'l')
    exe 'normal! "'.v:register.a:how
    call setreg(v:register, body, type)
  endif
  silent! call repeat#set("\<Plug>unimpairedPut".a:map)
endfunction

nnoremap <silent> <Plug>unimpairedPutAbove :call <SID>putline('[p', 'Above')<CR>
nnoremap <silent> <Plug>unimpairedPutBelow :call <SID>putline(']p', 'Below')<CR>

call s:map('n', '[p', '<Plug>unimpairedPutAbove')
call s:map('n', ']p', '<Plug>unimpairedPutBelow')
call s:map('n', '[P', '<Plug>unimpairedPutAbove')
call s:map('n', ']P', '<Plug>unimpairedPutBelow')
call s:map('n', '>P', ":<C-U>call <SID>putline(v:count1 . '[p', 'Above')<CR>>']", '<silent>')
call s:map('n', '>p', ":<C-U>call <SID>putline(v:count1 . ']p', 'Below')<CR>>']", '<silent>')
call s:map('n', '<P', ":<C-U>call <SID>putline(v:count1 . '[p', 'Above')<CR><']", '<silent>')
call s:map('n', '<p', ":<C-U>call <SID>putline(v:count1 . ']p', 'Below')<CR><']", '<silent>')
call s:map('n', '=P', ":<C-U>call <SID>putline(v:count1 . '[p', 'Above')<CR>=']", '<silent>')
call s:map('n', '=p', ":<C-U>call <SID>putline(v:count1 . ']p', 'Below')<CR>=']", '<silent>')

" Section: Encoding and decoding

function! s:string_encode(str) abort
  let map = {"\n": 'n', "\r": 'r', "\t": 't', "\b": 'b', "\f": '\f', '"': '"', '\': '\'}
  return substitute(a:str,"[\001-\033\\\\\"]",'\="\\".get(map,submatch(0),printf("%03o",char2nr(submatch(0))))','g')
endfunction

function! s:string_decode(str) abort
  let map = {'n': "\n", 'r': "\r", 't': "\t", 'b': "\b", 'f': "\f", 'e': "\e", 'a': "\001", 'v': "\013", "\n": ''}
  let str = a:str
  if str =~# '^\s*".\{-\}\\\@<!\%(\\\\\)*"\s*\n\=$'
    let str = substitute(substitute(str,'^\s*\zs"','',''),'"\ze\s*\n\=$','','')
  endif
  return substitute(str,'\\\(\o\{1,3\}\|x\x\{1,2\}\|u\x\{1,4\}\|.\)','\=get(map,submatch(1),submatch(1) =~? "^[0-9xu]" ? nr2char("0".substitute(submatch(1),"^[Uu]","x","")) : submatch(1))','g')
endfunction

function! s:Transform(algorithm,type) abort
  let sel_save = &selection
  let cb_save = &clipboard
  set selection=inclusive clipboard-=unnamed clipboard-=unnamedplus
  let reg_save = @@
  if a:type ==# 'line'
    silent exe "normal! '[V']y"
  elseif a:type ==# 'block'
    silent exe "normal! `[\<C-V>`]y"
  else
    silent exe "normal! `[v`]y"
  endif
  if a:algorithm =~# '^\u\|#'
    let @@ = {a:algorithm}(@@)
  else
    let @@ = s:{a:algorithm}(@@)
  endif
  norm! gvp
  let @@ = reg_save
  let &selection = sel_save
  let &clipboard = cb_save
endfunction

function! s:TransformOpfunc(type) abort
  return s:Transform(s:encode_algorithm, a:type)
endfunction

function! s:TransformSetup(algorithm) abort
  let s:encode_algorithm = a:algorithm
  let &opfunc = matchstr(expand('<sfile>'), '<SNR>\d\+_').'TransformOpfunc'
  return 'g@'
endfunction

function! UnimpairedMapTransform(algorithm, key) abort
  exe 'nnoremap <expr> <Plug>unimpaired_'    .a:algorithm.' <SID>TransformSetup("'.a:algorithm.'")'
  exe 'xnoremap <expr> <Plug>unimpaired_'    .a:algorithm.' <SID>TransformSetup("'.a:algorithm.'")'
  exe 'nnoremap <expr> <Plug>unimpaired_line_'.a:algorithm.' <SID>TransformSetup("'.a:algorithm.'")."_"'
  call s:map('n', a:key, '<Plug>unimpaired_'.a:algorithm)
  call s:map('x', a:key, '<Plug>unimpaired_'.a:algorithm)
  call s:map('n', a:key.a:key[strlen(a:key)-1], '<Plug>unimpaired_line_'.a:algorithm)
endfunction

call UnimpairedMapTransform('string_encode','[y')
call UnimpairedMapTransform('string_decode',']y')

" Section: Activation

call s:maps()

" vim:set sw=2 sts=2:
