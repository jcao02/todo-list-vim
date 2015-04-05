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

" Gets the line number of the current task
fu! s:GetLineNumber()
    let l:line = getline('.')

    if len(l:line) == 0
        return -1
    endif

    "" Later we can handle file too
    let l:lineinfo = matchstr(l:line, ':\d\+')

    if l:lineinfo == ""
        return -1
    endif

    let l:lineno = strpart(l:lineinfo, 1) + 0

    if (l:lineno > 0)
        return l:lineno
    else
        return -1
    endif
endfu

fu! s:LineSearchLoop()

    " Don't do anything if the buffer is not a TODO list
    if stridx(expand("%:t"), 'TODO_') == -1
        return
    endif

    match none
    let l:lineno = <SID>GetLineNumber()

    if (l:lineno == -1) 
        return
    endif
    
    " To highlight the current line in the todo list
    exe 'match Search /\%'.line(".").'l.*/'

    let l:bufnr = b:original_bufnr
    exe bufwinnr(l:bufnr).' wincmd w'


    match none
    exe 'normal! '.l:lineno.'Gzz'
    " To highlight the current line in the file
    exe 'match Search /\%'.line(".").'l.*/'

    exe bufwinnr('TODO_'.l:bufnr).' wincmd w'
endfu

" Opens a buffer to show the items found
fu! s:OpenBuffer(bufferno)

    let l:bufferMaxSize = 20
    lockvar l:bufferMaxSize
    let l:matches = <SID>SearchTokens()

    if l:matches == 0
        echo "No pending tasks in this file"
        return
    endif

    if (l:matches > l:bufferMaxSize)
        let l:matches = l:bufferMaxSize
    endif

    " Split the screen into new buffer
    exe l:matches.'sp TODO_'.a:bufferno

    set noswapfile
    set modifiable
    " Paste the register and erase last line 
    norm! "tPGddgg

    " Cleanup the register t
    let @t = ""
    set nomodified

    let b:original_bufnr = a:bufferno

    " Create maps to close the window
    nnoremap <Leader>q :call <SID>Exit(0)<cr>

    let s:old_updatetime = &updatetime
    set updatetime=350
    au! CursorHold <buffer> nested call <SID>LineSearchLoop()
endfu

" Closes the buffer where the list is displayed
fu! s:Exit(exitcode)

    let l:todo_bufnr = bufnr('TODO_'.b:original_bufnr)
    echo l:todo_bufnr
    exe l:todo_bufnr.'bd!'

    " Unmap the exit
    nunmap <Leader>q

    " Remove matches and recover update time
    match none
    exe 'set updatetime='.s:old_updatetime

    let l:bufnr = b:original_bufnr
    exe bufwinnr(l:bufnr).' wincmd w'

    " Recover cursor position
    let l:original_line = b:original_line
    exe 'normal! '.l:original_line.'Gzz'
endfu

" Writes the content of the register in a file
fu! s:WriteToFile()
endfu

" Parses the current directory for tokens and store them in the register
fu! s:parseDirectory(directory)
endfu


fu s:TodoList()
    let b:original_line = line('.')
    let b:original_bufnr = bufnr('%')
    let l:current_buffer = b:original_bufnr
    :call <SID>OpenBuffer(l:current_buffer)
endfu

" ===== Commands =====
command! TodoList call s:TodoList()

" ===== Mapping =====
if !exists('g:todo_list_map_keys')
    let g:todo_list_map_keys = 1
endif


noremap <Plug>TodoList :TodoList

if g:todo_list_map_keys
    echo "hola"
    nmap <silent> <Leader>t <Plug>TodoList<CR>
endif
