let s:git_scratch_buffer = '__GitScratch__'

function! git#helpers#OpenScratchBuffer()
    call git#helpers#OpenTempBuffer(s:git_scratch_buffer)
endfunction

function! git#helpers#CdToGitRoot()
    let l:git_root = git#helpers#FindFolder(".git") . "/.."
    call git#helpers#WriteLine("Locally changing directory to : " . l:git_root)
    execute "lcd " . l:git_root
endfunction

function! git#helpers#OpenTempBuffer(name)
    execute "edit " . a:name
    setlocal modifiable noreadonly
    setlocal nobuflisted buftype=nofile bufhidden=wipe
    execute "normal! ggdG" 
endfunction

function! git#helpers#CountRemainingWindows()
    let t:window_count = 0
    silent windo let t:window_count = t:window_count + 1
    return t:window_count
endfunction

function! git#helpers#WriteLine(line)
    execute "normal! I" .  a:line . "\<cr>"
endfunction

function! git#helpers#BufferReadOnly()
    setlocal nomodifiable readonly
endfunction

function! git#helpers#FindFolder(folder)
    let current_dir = expand("%:p:h") 

    let i = 0
    while i <= 10
        " echo "Looking for folder " . a:folder . " at " . current_dir
        let found = globpath(current_dir, a:folder, 0, 1)

        if len(found) > 0
            " echom "Found folder " . found[0]
            let l:folder = found[0]
            python3 << EOF
import os
import vim
vim.command('let l:folder = \'' + os.path.abspath(vim.eval('l:folder')) + '\'')
EOF
            return l:folder
        endif

        let i = i + 1
        let current_dir = current_dir . '/..'
    endwhile
endfunction
