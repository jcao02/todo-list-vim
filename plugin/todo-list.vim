" File: todo-list.vim
" Author: Juan Carlos Arocha
" Description: Plugin to list TODO, FIXME and any other token in a tasks list


" ====== Tokens ======
if !exists("g:TodoListTokens")
    let g:TodoListTokens = [ "FIXME", "XXX", "TODO" ]
endif

if !exists("g:todo_file_ext")
    let g:todo_file_ext = 'td'
endif

" ====== Private functions ======

" Search the tokens in current file
fu! s:search_tokens(format_fn)

    let l:filename     = expand('%p:h')
    let l:index        = 0
    let l:matches      = 0
    let l:matches_list = []
    while (l:index < len(g:TodoListTokens))
        " Getting the token to search
        let l:token = g:TodoListTokens[l:index]


        " We start search at the top of the file
        normal! gg0
        let l:lineno = search(l:token, "Wc")
        while (l:lineno > 0)
            let l:matches += 1

            let l:linetext  = getline(l:lineno)
            let l:text      = a:format_fn(l:filename, l:lineno, l:linetext, l:token)

            call add(l:matches_list, l:text)
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

    return [l:matches, l:matches_list]
endfu

" Format a task to be shown in buffer
fu! s:format_item_buffer(filename, lineno, linetext, token)
    let l:text = '('.a:filename.':'.a:lineno.') '
    let l:text .= strpart(a:linetext, strridx(a:linetext, a:token))

    return l:text
endfu

" Format a task to be written in file
fu! s:format_item_file(filename, lineno, linetext, token)
    if a:token == "FIXME"
        let l:priority = "(A)"
    elseif a:token == "XXX"
        let l:priority = "(B)"
    else
        let l:priority = "(C)"
    endif

    let l:text = '- [ ] ('.a:filename.':'.a:lineno.') '
    let l:text .= strpart(a:linetext, strridx(a:linetext, a:token))
    let l:text .= l:priority

    return l:text
endfu

" Gets the line number of the current task
fu! s:get_line_number()
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

fu! s:line_search_loop()

    " Don't do anything if the buffer is not a TODO list
    if stridx(expand("%:t"), 'TODO_') == -1
        return
    endif

    match none
    let l:lineno = <SID>get_line_number()

    if (l:lineno == -1) 
        return
    endif
    
    " To highlight the current line in the todo list
    exe 'match PmenuSel /\%'.line(".").'l.*/'

    let l:bufnr = b:original_bufnr
    exe bufwinnr(l:bufnr).' wincmd w'


    match none
    exe 'normal! '.l:lineno.'Gzz'
    " To highlight the current line in the file
    exe 'match PmenuSel /\%'.line(".").'l.*/'

    exe bufwinnr('TODO_'.l:bufnr).' wincmd w'
endfu

" Opens a buffer to show the items found
fu! s:open_buffer(bufferno)

    let l:bufferMaxSize = 20
    lockvar l:bufferMaxSize
    let [l:matches, l:matches_list] = <SID>search_tokens(function("<SID>format_item_buffer"))

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
    call setline(1, l:matches_list)
    set nomodified
    set nomodifiable

    let b:original_bufnr = a:bufferno

    au! CursorMoved <buffer> nested call <SID>line_search_loop()
endfu

" Closes the buffer where the list is displayed
fu! s:exit(exitcode)

    let l:todo_bufnr = bufnr('TODO_'.b:original_bufnr)
    exe l:todo_bufnr.'bd!'

    " Remove matches
    match none

    let l:bufnr = b:original_bufnr
    exe bufwinnr(l:bufnr).' wincmd w'

    " Recover cursor position
    let l:original_line = b:original_line
    exe 'normal! '.l:original_line.'Gzz'
endfu

" Writes the content of the register in a file
fu! s:write_to_file()
    let l:filename = expand('%t:h')
    let l:basename = matchstr(l:filename, '\w\+\ze[.]') 

    if len(l:basename) > 0
        let l:todo_filename =  l:basename . '.'.g:todo_file_ext
    else
        let l:todo_filename =  l:filename . '.'.g:todo_file_ext
    endif

    let [l:matches, l:matches_list] = <SID>search_tokens(function("<SID>format_item_file"))

    
    let l:header = [ '# TODO list', '# Created at: '.strftime('%Y-%m-%d %H:%M:%S'), '' ]
    let l:todolist = l:header + l:matches_list
    echon "Writing todo list into file ". l:todo_filename . "... "
    call writefile(l:todolist, l:todo_filename)
    echon "done"

endfu

" Parses the current directory for tokens and store them in the register
fu! s:parseDirectory(directory)
endfu


fu! s:todo_list()
    if !exists("b:original_line")
        let b:original_line  = line('.')
    endif
    if !exists("b:original_bufnr")
        let b:original_bufnr = bufnr('%')
    endif
    let l:current_buffer = b:original_bufnr

    if buflisted('TODO_'.b:original_bufnr)
        call <SID>exit(0)
    else
        :call <SID>open_buffer(l:current_buffer)
    endif
endfu

" ===== Commands =====
command! TodoList call <SID>todo_list()
command! WriteTodoList call <SID>write_to_file()

" ===== Mapping =====
if !exists('g:todo_list_map_keys')
    let g:todo_list_map_keys = 1
endif

noremap <Plug>TodoList :TodoList

if g:todo_list_map_keys
    nmap <silent> <Leader>t <Plug>TodoList<CR>
endif
