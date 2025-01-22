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
function! AddErrtagsNotice(lnum, col, message)
  try " NOTE: the column might have been deleted, thats no excuse to halt and catch fire
    call prop_add(a:lnum, a:col, {
          \ 'type': 'ErrtagsHighlight',
          \ 'length': 1
          \ })
  catch /E964/ | endtry

    call prop_add(a:lnum, 0, {
          \ 'type': 'ErrtagsMessage',
          \ 'text': ' # E: ' . a:message,
          \ 'text_align': 'after'
          \ })
endfunction

function AddErrtagsNotices(notices)
    for l:notice in a:notices
        if fnamemodify(l:notice['fname'], ':t') == expand('%:t')
            call AddErrtagsNotice(l:notice.lnum, l:notice.col, l:notice.text)
        endif
    endfor
endfunction

function! ParseErrtagsNotices(lines)
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

function! DoErrtagsNotices()
    call prop_remove({ 'type': 'ErrtagsHighlight' })
    call prop_remove({ 'type': 'ErrtagsMessage' })

    try
        let l:lines = readfile(g:errtags_cache)
    catch /E484/
        return
    endtry

    let l:notices = ParseErrtagsNotices(l:lines)

    call AddErrtagsNotices(l:notices)
endfunction
" #pragma endregion

" --- Hook up everything ---
" #pragma region
if exists('g:errtags_events')
	for e in g:errtags_events
		execute "autocmd " . e . " * DoErrtagsNotices"
	endfor
endif

if expand('$ERRTAGS_CACHE_FILE') != '$ERRTAGS_CACHE_FILE'
    let g:errtags_cache = expand('$ERRTAGS_CACHE_FILE')
else
    let g:errtags_cache = expand('$XDG_CACHE_HOME/errtags.tags')
endif

command! DoErrtagsNotices :call DoErrtagsNotices()
" #pragma endregion
