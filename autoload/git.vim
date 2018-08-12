function! git#GetCurrentBranch()
    let l:status_out = system("git status")
    let l:on_branch =  "On branch"
    let l:branch_index_from = match(l:status_out, l:on_branch) + strlen(l:on_branch) + 1
    let l:branch_index_to = match(l:status_out, "\n", l:branch_index_from)
    let l:branch_name = strpart(l:status_out, l:branch_index_from, l:branch_index_to - l:branch_index_from)

    return l:branch_name
endfunction

function! git#PushToCurrentBranch()
    call helpers#OpenScratchBuffer()
    execute "normal! gg"
    silent execute "read !bash -c \"git push origin HEAD:" .  GetCurrentBranch() . "\""
    execute "normal! gg"
    silent!  /http
endfunction

function! git#GitFetchAndMergeOriginMaster()
    call helpers#OpenScratchBuffer()
    execute "normal! gg"
    silent! execute "read !bash -c \"git fetch\""
    silent! execute "read !bash -c \"git merge origin/master\""
    execute "normal! gg"
endfunction

function! git#GitRefLog()
    call helpers#OpenScratchBuffer()
    execute "normal! gg"
    execute "read !bash -c \"git reflog -n 100 \""
    execute "normal! gg"
endfunction

function! git#GitShowCommit()
    let l:selected_commit = expand("<cword>")
    call helpers#OpenScratchBuffer()
    execute "normal! gg"
    execute "read !bash -c \"git show " . l:selected_commit . "\""
    execute "normal! gg"
    set filetype=diff
endfunction

function! git#GitCommitTerminal()
    terminal git commit -v
    normal! i
endfunction

function! git#GitCommitEditMessage()
    call helpers#OpenScratchBuffer()
    nunmap <buffer> j
    nunmap <buffer> k
    nunmap <buffer> <CR>

    silent execute "read !git status"
    execute "/On branch"
    execute "normal! ggdd0d2wjdG"
    execute "normal! ggA: " 

    function! git#GitCommitDispose()
        nnoremap <buffer> <leader>gc :call GitCommitEditMessage()<CR>
        nunmap <buffer> <leader>gnc
        normal! ggdGI pclose to close this window

        if helpers#CountRemainingWindows() > 1
            silent! pclose
        endif
    endfunction

    function! git#GitCommitDone()
        " call helpers#OpenScratchBuffer()
        " silent wincmd P
        silent execute "normal! /Available commands\<cr>"
        1,$-1d  " delete all lines except for the last one

        silent write !bash -c 'git commit --file=-'
        call GitCommitDispose()
    endfunction

    nnoremap <buffer> <leader>gc :call GitCommitDone()<cr>
    nnoremap <buffer> <leader>gnc :call GitCommitDispose()<CR>

    execute "normal! O\<cr>"
    call helpers#WriteLine('Available commandhelpers#')
    call helpers#WriteLine('===================')
    call helpers#WriteLine('')
    call helpers#WriteLine('gc - commit')
    call helpers#WriteLine('gnc - do not commit')
    call helpers#WriteLine('')
    normal! GA
endfunction

function! git#GitBlame()
    let l:current_file = expand("%")
    let l:current_line = line(".")

    call helpers#OpenScratchBuffer()

    execute "normal! gg"
    call helpers#WriteLine('Available commandhelpers#')
    call helpers#WriteLine('===================')
    call helpers#WriteLine('')
    call helpers#WriteLine('gsh - show')
    call helpers#WriteLine('')

    silent execute 'read !git blame --date=relative '  . l:current_file
    execute "normal! gg" . l:current_line . "j5jzz"

    nnoremap <buffer> <leader>gsh :call GitShowCommit()<CR>

    call helpers#BufferReadOnly()
endfunction

function! git#GitLog()
    call helpers#OpenScratchBuffer()

    execute "normal! gg"
    call helpers#WriteLine('Available commandhelpers#')
    call helpers#WriteLine('===================')
    call helpers#WriteLine('')
    call helpers#WriteLine('gsh - show')
    call helpers#WriteLine('gn - next commit')
    call helpers#WriteLine('')

    silent execute 'read !git log --oneline --max-count 15 --format="\%h: [\%an] \%s"' 
    execute "normal! gg"

    nnoremap <buffer> <leader>gsh :call GitShowCommit()<CR>
    nnoremap <buffer> <leader>gn /\x\{7}:<cr>z<CR>:nohlsearch<CR>

    call helpers#BufferReadOnly()
endfunction

function! git#GitStatus()
    call helpers#OpenScratchBuffer()

    silent execute "read !git status --short" 
    execute "normal! gg"
    call helpers#WriteLine('Available commandhelpers#')
    call helpers#WriteLine('===================')
    call helpers#WriteLine('')
    call helpers#WriteLine('gaf - add')
    call helpers#WriteLine('gk - checkout')
    call helpers#WriteLine('gn - next file')
    call helpers#WriteLine('')

    call helpers#CdToGitRoot()

    vnoremap <buffer> <leader>gaf y:silent !git add <C-R>"<CR>:call GitStatus()<CR>
    nnoremap <buffer> <leader>gaf y$:silent !git add <C-R>"<cr>:call GitStatus()<CR>
    vnoremap <buffer> <leader>gk y:silent !git checkout -- <C-R>"<CR>:call GitStatus()<CR>
    nnoremap <buffer> <leader>gk y$:silent !git checkout -- <C-R>"<cr>:call GitStatus()<CR>
    nnoremap <buffer> <leader>gn j^w

    call helpers#BufferReadOnly()
endfunction

function! git#GitDiff(args)
    call helpers#OpenScratchBuffer()

    silent execute "read !git diff -w " . a:args
    silent g/warning: LF will be replaced by CRLF in/normal! dd 
    silent g/The file will have its original line endings in your working directory./normal! dd 
    execute "normal! gg"

    call helpers#WriteLine('Available commandhelpers#')
    call helpers#WriteLine('===================')
    call helpers#WriteLine('')
    call helpers#WriteLine('gaf/CR - add a file')
    call helpers#WriteLine('gk - checkout file')
    call helpers#WriteLine('gr - reset file')
    call helpers#WriteLine('j - next file')
    call helpers#WriteLine('k - previous file')
    call helpers#WriteLine('')

    setlocal filetype=diff 

    call helpers#CdToGitRoot()

    let @d=a:args

    vnoremap <buffer> <leader>gaf y:silent !git add <C-R>"<CR>:call GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gaf y$:silent !git add <C-R>"<cr>:call GitDiff('<C-R>d')<CR>
    vnoremap <buffer> <leader>gk y:silent !git checkout -- <C-R>"<CR>:call GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gk y$:silent !git checkout -- <C-R>"<cr>:call GitDiff('<C-R>d')<CR>
    vnoremap <buffer> <leader>gr y:silent !git  reset HEAD <C-R>"<CR>:call GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gr y$:silent !git reset HEAD <C-R>"<cr>:call GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gn /+++ b<cr>z<CR>6l:nohlsearch<CR>
    nnoremap <buffer> <leader>j /+++ b<cr>z<CR>6l:nohlsearch<CR>
    nnoremap <buffer> <leader>k ?+++ b<cr>nz<CR>6l:nohlsearch<CR>
    nnoremap <buffer> <CR> y$:silent !git add <C-R>"<cr>:call GitDiff('<C-R>d')<CR>

    call helpers#BufferReadOnly()
endfunction

function! git#GitNewBranch()
    let l:branch_name = input("New branch name: ")
    execute "!git checkout origin/master -b " . l:branch_name
endfunction

function! git#GitHelp()
    call helpers#OpenScratchBuffer()
    call helpers#WriteLine("Git commandhelpers#\<cr>")
    call helpers#WriteLine("gaa: Add all")
    call helpers#WriteLine("gaf: Add file under cursor")
    call helpers#WriteLine("gdf: git diff")
    call helpers#WriteLine("gdc: git diff --cached")
    call helpers#WriteLine("glo: git log")
    call helpers#WriteLine("gfo: git fetch")
    call helpers#WriteLine("gpb: git push")
    call helpers#WriteLine("gbr: git branch")
    call helpers#WriteLine("gbl: git blame")
    call helpers#WriteLine("gst: git status")
    call helpers#WriteLine("gco: git commit")
    call helpers#WriteLine("gch: git checkout -b")
    call helpers#WriteLine("grl: git reflog")
    call helpers#WriteLine("gmm: git fetch/merge origin/master")
    call helpers#WriteLine("\<cr>")
    call helpers#WriteLine("General commandhelpers#")
    call helpers#WriteLine("chelpers# close scratch buffer")
    execute "normal! gg"

    call helpers#BufferReadOnly()
endfunction
