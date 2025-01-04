" --- Define our prop types ---
" #pragma region
call prop_type_delete('ErrorHighlight')
call prop_type_delete('CommentHighlight')

hi link ErrTagsError   ErrorMsg
hi link ErrTagsMessage Comment

call prop_type_add('ErrorHighlight', {
      \ 'highlight': 'ErrTagsError',
      \ })

call prop_type_add('CommentHighlight', {
      \ 'highlight': 'ErrTagsMessage',
      \ })
" #pragma endregion

" --- Main logic ---
" #pragma region
function! AddNotice(lnum, col, message)
  try
    call prop_add(a:lnum, a:col, {
          \ 'type': 'ErrorHighlight',
          \ 'length': 1
          \ })
  catch /E964/ | endtry

    call prop_add(a:lnum, 0, {
          \ 'type': 'CommentHighlight',
          \ 'text': ' # E: ' . a:message,
          \ 'text_align': 'after'
          \ })
endfunction

function AddNotices(notices)
    for l:notice in a:notices
        if l:notice['fname'] == expand('%:t')
            call AddNotice(l:notice.lnum, l:notice.col, l:notice.text)
        endif
    endfor
endfunction

function! ParseNotices(lines)
    let l:errors = []

    for l:line in a:lines
        let l:fields = split(l:line, ':')

        if len(l:fields) >= 2
            let l:filename = l:fields[0]
            let l:line_number = l:fields[1]
            let l:column_number = l:fields[2]
            let l:message = join(l:fields[3:], ':')

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

function! DoNotices()
    call prop_remove({ 'type': 'ErrorHighlight' })
    call prop_remove({ 'type': 'CommentHighlight' })

    let l:lines = readfile(expand('~/stow/.cache/errtags.tags'))

    let l:notices = ParseNotices(l:lines)

    call AddNotices(l:notices)
endfunction
" #pragma endregion

" --- Hook up everything ---
" #pragma region
if exists('g:errtags_events')
	for e in g:errtags_events
		execute "autocmd " . e . " * DoNotices"
	endfor
endif

command! DoNotices :call DoNotices()
" #pragma endregion
