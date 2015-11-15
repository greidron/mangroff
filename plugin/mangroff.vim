" Vim plugin for viewing man page using groff. 
" Maintainer: IKyun Jin <greidron@gmail.com>
" Last Change: 2015-11-11

if !exists('g:manpath')
    let g:manpath = $VIMRUNTIME . '/man-pages'
endif

" Check path slash.
function! MangroffCheckSlash(path)
    if has('win32')
        return substitute(a:path, '/', '\', 'g')
    else
        return substitute(a:path, '\', '/', 'g')
    endif
endfunction

" Escape file path.
function! MangroffEscapePath(path)
    let l:ss_old = &shellslash
    let l:path = a:path
    if has('win32')
        " No shell slash & replace slash to backslash.
        setlocal noshellslash
    endif
    let escaped_path = shellescape(l:path)
    let &shellslash = l:ss_old
    return escaped_path
endfunction

" Get man page path.
function! MangroffManPath(section, name)
    let l:dirs = globpath(g:manpath, 'man*')
    for l:dir in split(l:dirs, '\n')
        if isdirectory(l:dir)
            let l:files = globpath(l:dir, a:name . '.' . a:section)
            for l:file in split(l:files, '\n')
                return l:file
            endfor
        endif
    endfor
    return ''
endfunction

" Load man page.
function! MangroffLoadPage(args)
    " Arguments.
    let l:argv = split(a:args, ' ')
    " Set section & entry name.
    let l:section = '*'
    let l:name = ''
    if len(l:argv) == 1
        let l:name = l:argv[0]
    elseif len(l:argv) == 2
        let l:section = l:argv[0]
        let l:name = l:argv[1]
    else
        echoerr 'Invalid argument format: Mng [section] name'
        return
    endif
    " Get man page file path.
    let l:path = MangroffManPath(l:section, l:name)
    let l:file_name = fnamemodify(l:path, ':t')
    if bufloaded(l:file_name)
        return
    endif
    if !filereadable(l:path)
        echoerr "No entry for '" . l:name . "'"
        return
    endif
    " Create new buffer if it's not the man page buffer.
    if !exists('b:is_mangroff')
        new
    else
        setlocal modifiable
        1,$d
    endif
    let b:is_mangroff = 'yes'
    setlocal buftype=nofile bufhidden=wipe nobuflisted noswapfile nowrap
    let l:man_contents = system('groff -man -Tascii ' . MangroffEscapePath(l:path))
    " Remove color codes.
    let l:output = substitute(l:man_contents, '\e\[[0-9;]\+[mK]', '', 'g')
    " Put output.
    put =l:output
    " Set title.
    execute 'file ' . l:file_name
    " Set readonly.
    setlocal nomodifiable
    " Set key mappings.
    nnoremap <buffer> q :q<CR>:<CR>
    nnoremap <buffer> n /^\S\+<CR>:nohlsearch<CR>:<CR>
    nnoremap <buffer> N ?^\S\+<CR>:nohlsearch<CR>:<CR>
    nnoremap <buffer> s /^SYNOPSIS<CR>:nohlsearch<CR>:<CR>
    nnoremap <buffer> d /^DESCRIPTION<CR>:nohlsearch<CR>:<CR>
    nnoremap <buffer> r /^RETURN VALUE<CR>:nohlsearch<CR>:<CR>
    nnoremap <buffer> e /^ERRORS<CR>:nohlsearch<CR>:<CR>
    " Move to first line.
    1
endfunction

" Mangroff command.
command! -nargs=* Mng call MangroffLoadPage( '<args>' )
