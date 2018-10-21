function! git#GetCurrentBranch()
    let l:status_out = system("git status")
    let l:on_branch =  "On branch"
    let l:branch_index_from = match(l:status_out, l:on_branch) + strlen(l:on_branch) + 1
    let l:branch_index_to = match(l:status_out, "\n", l:branch_index_from)
    let l:branch_name = strpart(l:status_out, l:branch_index_from, l:branch_index_to - l:branch_index_from)

    return l:branch_name
endfunction

function! git#PushToCurrentBranch()
    call git#helpers#OpenScratchBuffer()
    execute "normal! gg"
    silent execute "term bash -c \"git push origin $(git remote | fzf --prompt 'Choose remote: '):" .  git#GetCurrentBranch() . "\""
    startinsert!
endfunction

function! git#GitFetchAndMergeOriginMaster()
    call git#helpers#OpenScratchBuffer()
    execute "normal! gg"
    silent! execute "read !bash -c \"git fetch\""
    silent! execute "read !bash -c \"git merge origin/master\""
    execute "normal! gg"
endfunction

function! git#GitRefLog()
    call git#helpers#OpenScratchBuffer()
    execute "normal! gg"
    execute "read !bash -c \"git reflog -n 100 \""
    execute "normal! gg"
endfunction

function! git#GitShowCommit()
    let l:selected_commit = expand("<cword>")
    call git#helpers#OpenScratchBuffer()
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
    call git#helpers#OpenScratchBuffer()
    nunmap <buffer> j
    nunmap <buffer> k
    nunmap <buffer> <CR>

    silent execute "read !git status"
    execute "/On branch"
    execute "normal! ggdd0d2wjdG"
    execute "normal! ggA: " 

    function! git#GitCommitDispose()
        nnoremap <buffer> <leader>gc :call git#GitCommitEditMessage()<CR>
        nunmap <buffer> <leader>gnc
        normal! ggdGI pclose to close this window

        if git#helpers#CountRemainingWindows() > 1
            silent! pclose
        endif
    endfunction

    function! git#GitCommitDone()
        " call git#helpers#OpenScratchBuffer()
        " silent wincmd P
        silent execute "normal! /Available commands\<cr>"
        1,$-1d  " delete all lines except for the last one

        silent write !bash -c 'git commit --file=-'
        call git#GitCommitDispose()
    endfunction

    nnoremap <buffer> <leader>gc :call git#GitCommitDone()<cr>
    nnoremap <buffer> <leader>gnc :call git#GitCommitDispose()<CR>

    execute "normal! O\<cr>"
    call git#helpers#WriteLine('Available commands')
    call git#helpers#WriteLine('===================')
    call git#helpers#WriteLine('')
    call git#helpers#WriteLine('gc - commit')
    call git#helpers#WriteLine('gnc - do not commit')
    call git#helpers#WriteLine('')
    normal! GA
endfunction

function! git#GitBlame()
    let l:current_file = expand("%")
    let l:current_line = line(".")

    call git#helpers#OpenScratchBuffer()

    execute "normal! gg"
    call git#helpers#WriteLine('Available commands')
    call git#helpers#WriteLine('===================')
    call git#helpers#WriteLine('')
    call git#helpers#WriteLine('gsh - show')
    call git#helpers#WriteLine('')

    silent execute 'read !git blame --date=relative '  . l:current_file
    execute "normal! gg" . l:current_line . "j5jzz"

    nnoremap <buffer> <leader>gsh :call git#GitShowCommit()<CR>

    call git#helpers#BufferReadOnly()
endfunction

function! git#GitLog()
    call git#helpers#OpenScratchBuffer()

    execute "normal! gg"
    call git#helpers#WriteLine('Available commands')
    call git#helpers#WriteLine('===================')
    call git#helpers#WriteLine('')
    call git#helpers#WriteLine('gsh - show')
    call git#helpers#WriteLine('gn - next commit')
    call git#helpers#WriteLine('')

    silent execute 'read !git log --oneline --max-count 15 --format="\%h: [\%an] \%s"' 
    execute "normal! gg"

    nnoremap <buffer> <leader>gsh :call git#GitShowCommit()<CR>
    nnoremap <buffer> <leader>gn /\x\{7}:<cr>z<CR>:nohlsearch<CR>

    call git#helpers#BufferReadOnly()
endfunction

function! git#GitStatus()
    call git#helpers#OpenScratchBuffer()

    silent execute "read !git status --short" 
    execute "normal! gg"
    call git#helpers#WriteLine('Available commands')
    call git#helpers#WriteLine('===================')
    call git#helpers#WriteLine('')
    call git#helpers#WriteLine('gaf - add')
    call git#helpers#WriteLine('gk - checkout')
    call git#helpers#WriteLine('gn - next file')
    call git#helpers#WriteLine('')

    call git#helpers#CdToGitRoot()

    vnoremap <buffer> <leader>gaf y:silent !git add <C-R>"<CR>:call git#GitStatus()<CR>
    nnoremap <buffer> <leader>gaf y$:silent !git add <C-R>"<cr>:call git#GitStatus()<CR>
    vnoremap <buffer> <leader>gk y:silent !git checkout -- <C-R>"<CR>:call git#GitStatus()<CR>
    nnoremap <buffer> <leader>gk y$:silent !git checkout -- <C-R>"<cr>:call git#GitStatus()<CR>
    nnoremap <buffer> <leader>gn j^w

    call git#helpers#BufferReadOnly()
endfunction

function! git#GitDiff(args)
    call git#helpers#OpenScratchBuffer()

    silent execute "read !git diff -w " . a:args
    silent g/warning: LF will be replaced by CRLF in/normal! dd 
    silent g/The file will have its original line endings in your working directory./normal! dd 
    execute "normal! gg"

    call git#helpers#WriteLine('Available commands')
    call git#helpers#WriteLine('===================')
    call git#helpers#WriteLine('')
    call git#helpers#WriteLine('gaf/CR - add a file')
    call git#helpers#WriteLine('gk - checkout file')
    call git#helpers#WriteLine('gr - reset file')
    call git#helpers#WriteLine('j - next file')
    call git#helpers#WriteLine('k - previous file')
    call git#helpers#WriteLine('')

    setlocal filetype=diff 

    call git#helpers#CdToGitRoot()

    let @d=a:args

    vnoremap <buffer> <leader>gaf y:silent !git add <C-R>"<CR>:call git#GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gaf y$:silent !git add <C-R>"<cr>:call git#GitDiff('<C-R>d')<CR>
    vnoremap <buffer> <leader>gk y:silent !git checkout -- <C-R>"<CR>:call git#GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gk y$:silent !git checkout -- <C-R>"<cr>:call git#GitDiff('<C-R>d')<CR>
    vnoremap <buffer> <leader>gr y:silent !git  reset HEAD <C-R>"<CR>:call git#GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gr y$:silent !git reset HEAD <C-R>"<cr>:call git#GitDiff('<C-R>d')<CR>
    nnoremap <buffer> <leader>gn /+++ b<cr>z<CR>6l:nohlsearch<CR>
    nnoremap <buffer> <leader>j /+++ b<cr>z<CR>6l:nohlsearch<CR>
    nnoremap <buffer> <leader>k ?+++ b<cr>nz<CR>6l:nohlsearch<CR>
    nnoremap <buffer> <CR> y$:silent !git add <C-R>"<cr>:call git#GitDiff('<C-R>d')<CR>

    call git#helpers#BufferReadOnly()
endfunction

function! git#GitNewBranch()
    let l:branch_name = input("New branch name: ")
    execute "!git checkout origin/master -b " . l:branch_name
endfunction

function! git#GitHelp()
    call git#helpers#OpenScratchBuffer()
    call git#helpers#WriteLine("Git commands\<cr>")
    call git#helpers#WriteLine("gaa: Add all")
    call git#helpers#WriteLine("gaf: Add file under cursor")
    call git#helpers#WriteLine("gdf: git diff")
    call git#helpers#WriteLine("gdc: git diff --cached")
    call git#helpers#WriteLine("glo: git log")
    call git#helpers#WriteLine("gfo: git fetch")
    call git#helpers#WriteLine("gpb: git push")
    call git#helpers#WriteLine("gbr: git branch")
    call git#helpers#WriteLine("gbl: git blame")
    call git#helpers#WriteLine("gst: git status")
    call git#helpers#WriteLine("gco: git commit")
    call git#helpers#WriteLine("gch: git checkout -b")
    call git#helpers#WriteLine("grl: git reflog")
    call git#helpers#WriteLine("gmm: git fetch/merge origin/master")
    call git#helpers#WriteLine("\<cr>")
    call git#helpers#WriteLine("General commands")
    call git#helpers#WriteLine("cs close scratch buffer")
    execute "normal! gg"

    call git#helpers#BufferReadOnly()
endfunction
