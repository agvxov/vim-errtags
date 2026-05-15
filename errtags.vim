" --- Define our prop types ---
" #pragma region
call prop_type_delete('ErrtagsHighlight')
call prop_type_delete('ErrtagsMessage')

hi link ErrTagsError   ErrorMsg
hi link ErrTagsMessage Comment

call prop_type_add('ErrtagsHighlight', {
      \ 'highlight': 'ErrTagsError',
      \ })

call prop_type_add('ErrtagsMessage', {
      \ 'highlight': 'ErrTagsMessage',
      \ })
" #pragma endregion

" --- Main logic ---
" #pragma region
function! ErrtagsAddNotice(lnum, col, message)
  try 
    call prop_add(a:lnum, a:col, {
          \ 'type': 'ErrtagsHighlight',
          \ 'length': 1
          \ })
  catch /E964/ | catch /E966/ | endtry

  try
    call prop_add(a:lnum, 0, {
          \ 'type': 'ErrtagsMessage',
          \ 'text': ' # E: ' . a:message,
          \ 'text_align': 'after'
          \ })
  catch /E964/ | catch /E966/ | endtry
endfunction

function ErrtagsAddNotices(notices)
    for l:notice in a:notices
        if fnamemodify(l:notice['fname'], ':t') == expand('%:t')
            call ErrtagsAddNotice(l:notice.lnum, l:notice.col, l:notice.text)
        endif
    endfor
endfunction

function! ErrtagsParseNotices(lines)
    let l:errors = []

    for l:line in a:lines
        let l:fields = split(l:line, ':')

        if len(l:fields) >= 2
            let l:filename      = l:fields[0]
            let l:line_number   = l:fields[1]
            let l:column_number = l:fields[2]
            let l:message       = join(l:fields[3:], ':')

            call add(l:errors, {
            \ 'fname': l:filename,
            \ 'lnum':  l:line_number,
            \ 'col':   l:column_number,
            \ 'text':  l:message,
            \ 'type':  'E',
            \ })
        endif
    endfor

    return l:errors
endfunction

function! ErrtagsClearNotices()
    call prop_remove({ 'all': 1, 'type': 'ErrtagsHighlight' })
    call prop_remove({ 'all': 1, 'type': 'ErrtagsMessage' })
endfunction

function! ErrtagsCleanNotices()
    call ErrtagsClearNotices()
    call writefile([], g:errtags_cache)
endfunction

function! ErrtagsDoNotices()
    call ErrtagsClearNotices()

    try
        let l:lines = readfile(g:errtags_cache)
    catch /E484/
        return
    endtry

    let l:notices = ErrtagsParseNotices(l:lines)

    call ErrtagsAddNotices(l:notices)
endfunction
" #pragma endregion

" --- Hook up everything ---
" #pragma region
if exists('g:errtags_events')
	for e in g:errtags_events
		execute "autocmd " . e . " * ErrtagsDoNotices"
	endfor
endif

if expand('$ERRTAGS_CACHE_FILE') != '$ERRTAGS_CACHE_FILE'
    let g:errtags_cache = expand('$ERRTAGS_CACHE_FILE')
elseif expand('$XDG_CACHE_HOME') != '$XDG_CACHE_HOME'
    let g:errtags_cache = expand('$XDG_CACHE_HOME/errtags.tags')
else
    let g:errtags_cache = ""
    echoerr "errtags: No cache; set $ERRTAGS_CACHE_FILE or $XDG_CACHE_HOME"
endif

command! ErrtagsDoNotices    :call ErrtagsDoNotices()
command! ErrtagsCleanNotices :call ErrtagsCleanNotices()
" #pragma endregion
