" File: todo-list.vim
" Author: Juan Carlos Arocha
" Description: Plugin to list TODO, FIXME and any other token in a tasks list


" ====== Tokens ======
if !exists("g:TodoListTokens")
    let g:TodoListTokens = [ "TODO", "FIXME", "XXX" ]
endif

" ====== Private functions ======

" Search the tokens in current file
fu! s:SearchTokens()

    let l:filename = expand('%p:h')
    let l:index = 0
    let l:matches = 0
    while (l:index < len(g:TodoListTokens))
        " Getting the token to search
        let l:token = g:TodoListTokens[l:index]


        " We start search at the top of the file
        normal! gg0
        let l:lineno = search(l:token, "Wc")
        while (l:lineno > 0)
            let l:matches += 1
            let l:linetext = getline(l:lineno)
            let l:text = '('.l:filename.':'.l:lineno.') '
            let l:text .= strpart(l:linetext, strridx(l:linetext, l:token))
            let @t .= l:text . "\n"
            " Last line: break
            if l:lineno == line('$')
                break
            endif

            " Put the cursor in the next line at col 1
            :call cursor(l:lineno + 1, 1)
            let l:lineno = search(l:token, "Wc")
        endwhile

        let l:index += 1
    endwhile

    return l:matches
endfu

" Format a task to be written or shown 
fu! s:FormatItem(item)
endfu

" Opens a buffer to show the items found
fu! s:OpenBuffer(bufferno)
    let l:bufferMaxSize = 20
    lockvar l:bufferMaxSize

    let l:matches = <SID>SearchTokens()
    if (l:matches > l:bufferMaxSize)
        let l:matches = l:bufferMaxSize
    endif

    " Split the screen into new buffer
    exe l:matches.'sp TODO'.a:bufferno

    set noswapfile
    set modifiable
    " Paste the register and erase last line 
    norm! "tPGddgg

    " Cleanup the register t
    let @t = ""
endfu

" Writes the content of the register in a file
fu! s:WriteToFile()
endfu

" Parses the current directory for tokens and store them in the register
fu! s:parseDirectory(directory)
endfu


fu s:TodoList()
    let l:current_window_buffer = bufnr('%')
    :call <SID>OpenBuffer(l:current_window_buffer)
endfu

" ====== Public functions (API) ======
" ===== Commands =====
command! TodoList call s:TodoList()
