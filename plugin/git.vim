if !has('nvim') || exists('git_vim_loaded')
  finish
endif

" Variables {{{
let git_vim_loaded = 1
let s:git_scratch_buffer = '__GitScratch__'
" }}}

" Commands {{{
command! -nargs=1 GitPush !bash -c "git push origin HEAD:<args>"
command! GitAddAll silent !git add -A
command! GitBlame call GitBlame()
command! GitBranchCurrent echom 'Current branch: ' . GetCurrentBranch()
command! GitBranchNew call GitNewBranch()
command! GitCommit call GitCommitTerminal()
command! GitDiff call GitDiff('')
command! GitDiffCached call GitDiff('--cached')
command! GitFetch silent terminal bash -c "git fetch"
command! GitHelp call GitHelp()
command! GitLog call GitLog()
command! GitFetchMaster call GitFetchAndMergeOriginMaster()
command! GitPushCurrentBranch call PushToCurrentBranch()
command! GetRefLog call GitRefLog()
command! GitStatus call GitStatus()
" }}}

" Functions {{{
function! GetCurrentBranch()
    let l:status_out = system("git status")
    let l:on_branch =  "On branch"
    let l:branch_index_from = match(l:status_out, l:on_branch) + strlen(l:on_branch) + 1
    let l:branch_index_to = match(l:status_out, "\n", l:branch_index_from)
    let l:branch_name = strpart(l:status_out, l:branch_index_from, l:branch_index_to - l:branch_index_from)

    return l:branch_name
endfunction

function! PushToCurrentBranch()
    call s:OpenScratchBuffer()
    execute "normal! gg"
    silent execute "read !bash -c \"git push origin HEAD:" .  GetCurrentBranch() . "\""
    execute "normal! gg"
    silent!  /http
endfunction

function! GitFetchAndMergeOriginMaster()
    call s:OpenScratchBuffer()
    execute "normal! gg"
    silent! execute "read !bash -c \"git fetch\""
    silent! execute "read !bash -c \"git merge origin/master\""
    execute "normal! gg"
endfunction

function! GitRefLog()
    call s:OpenScratchBuffer()
    execute "normal! gg"
    execute "read !bash -c \"git reflog -n 100 \""
    execute "normal! gg"
endfunction

function! GitShowCommit()
    let l:selected_commit = expand("<cword>")
    call s:OpenScratchBuffer()
    execute "normal! gg"
    execute "read !bash -c \"git show " . l:selected_commit . "\""
    execute "normal! gg"
    set filetype=diff
endfunction

function! GitCommitTerminal()
    terminal git commit -v
    normal! i
endfunction

function! GitCommitEditMessage()
    call s:OpenScratchBuffer()
    nunmap <buffer> j
    nunmap <buffer> k
    nunmap <buffer> <CR>

    silent execute "read !git status"
    execute "/On branch"
    execute "normal! ggdd0d2wjdG"
    execute "normal! ggA: " 

    function! GitCommitDispose()
        nnoremap <buffer> <leader>gc :call GitCommitEditMessage()<CR>
        nunmap <buffer> <leader>gnc
        normal! ggdGI pclose to close this window

        if s:CountRemainingWindows() > 1
            silent! pclose
        endif
    endfunction

    function! GitCommitDone()
        " call s:OpenScratchBuffer()
        " silent wincmd P
        silent execute "normal! /Available commands\<cr>"
        1,$-1d  " delete all lines except for the last one

        silent write !bash -c 'git commit --file=-'
        call GitCommitDispose()
    endfunction

    nnoremap <buffer> <leader>gc :call GitCommitDone()<cr>
    nnoremap <buffer> <leader>gnc :call GitCommitDispose()<CR>

    execute "normal! O\<cr>"
    call s:WriteLine('Available commands:')
    call s:WriteLine('===================')
    call s:WriteLine('')
    call s:WriteLine('gc - commit')
    call s:WriteLine('gnc - do not commit')
    call s:WriteLine('')
    normal! GA
endfunction

function! GitBlame()
    let l:current_file = expand("%")
    let l:current_line = line(".")

    call s:OpenScratchBuffer()

    execute "normal! gg"
    call s:WriteLine('Available commands:')
    call s:WriteLine('===================')
    call s:WriteLine('')
    call s:WriteLine('gsh - show')
    call s:WriteLine('')

    silent execute 'read !git blame --date=relative '  . l:current_file
    execute "normal! gg" . l:current_line . "j5jzz"

    nnoremap <buffer> <leader>gsh :call GitShowCommit()<CR>

    call s:BufferReadOnly()
endfunction

function! GitLog()
    call s:OpenScratchBuffer()

    execute "normal! gg"
    call s:WriteLine('Available commands:')
    call s:WriteLine('===================')
    call s:WriteLine('')
    call s:WriteLine('gsh - show')
    call s:WriteLine('gn - next commit')
    call s:WriteLine('')

    silent execute 'read !git log --oneline --max-count 15 --format="\%h: [\%an] \%s"' 
    execute "normal! gg"

    nnoremap <buffer> <leader>gsh :call GitShowCommit()<CR>
    nnoremap <buffer> <leader>gn /\x\{7}:<cr>z<CR>:nohlsearch<CR>

    call s:BufferReadOnly()
endfunction

function! GitStatus()
    call s:OpenScratchBuffer()

    silent execute "read !git status --short" 
    execute "normal! gg"
    call s:WriteLine('Available commands:')
    call s:WriteLine('===================')
    call s:WriteLine('')
    call s:WriteLine('gaf - add')
    call s:WriteLine('gk - checkout')
    call s:WriteLine('gn - next file')
    call s:WriteLine('')

    call s:CdToGitRoot()

    vnoremap <buffer> <leader>gaf y:silent !git add <C-R>"<CR>:call GitStatus()<CR>
    nnoremap <buffer> <leader>gaf y$:silent !git add <C-R>"<cr>:call GitStatus()<CR>
    vnoremap <buffer> <leader>gk y:silent !git checkout -- <C-R>"<CR>:call GitStatus()<CR>
    nnoremap <buffer> <leader>gk y$:silent !git checkout -- <C-R>"<cr>:call GitStatus()<CR>
    nnoremap <buffer> <leader>gn j^w

    call s:BufferReadOnly()
endfunction

function! GitDiff(args)
    call s:OpenScratchBuffer()

    silent execute "read !git diff -w " . a:args
    silent g/warning: LF will be replaced by CRLF in/normal! dd 
    silent g/The file will have its original line endings in your working directory./normal! dd 
    execute "normal! gg"

    call s:WriteLine('Available commands:')
    call s:WriteLine('===================')
    call s:WriteLine('')
    call s:WriteLine('gaf/CR - add a file')
    call s:WriteLine('gk - checkout file')
    call s:WriteLine('gr - reset file')
    call s:WriteLine('j - next file')
    call s:WriteLine('k - previous file')
    call s:WriteLine('')

    setlocal filetype=diff 

    call s:CdToGitRoot()

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

    call s:BufferReadOnly()
endfunction

function! GitNewBranch()
    let l:branch_name = input("New branch name: ")
    execute "!git checkout origin/master -b " . l:branch_name
endfunction

function! GitHelp()
    call s:OpenScratchBuffer()
    call s:WriteLine("Git commands:\<cr>")
    call s:WriteLine("gaa: Add all")
    call s:WriteLine("gaf: Add file under cursor")
    call s:WriteLine("gdf: git diff")
    call s:WriteLine("gdc: git diff --cached")
    call s:WriteLine("glo: git log")
    call s:WriteLine("gfo: git fetch")
    call s:WriteLine("gpb: git push")
    call s:WriteLine("gbr: git branch")
    call s:WriteLine("gbl: git blame")
    call s:WriteLine("gst: git status")
    call s:WriteLine("gco: git commit")
    call s:WriteLine("gch: git checkout -b")
    call s:WriteLine("grl: git reflog")
    call s:WriteLine("gmm: git fetch/merge origin/master")
    call s:WriteLine("\<cr>")
    call s:WriteLine("General commands:")
    call s:WriteLine("cs: close scratch buffer")
    execute "normal! gg"

    call s:BufferReadOnly()
endfunction
" }}}

" Helpers {{{
function! s:OpenScratchBuffer()
    call s:OpenTempBuffer(s:git_scratch_buffer)
endfunction

function! s:CdToGitRoot()
    let l:git_root = s:FindFolder(".git") . "/.."
    call s:WriteLine("Locally changing directory to : " . l:git_root)
    execute "lcd " . l:git_root
endfunction

function! s:OpenTempBuffer(name)
    execute "edit " . a:name
    setlocal modifiable noreadonly
    setlocal nobuflisted buftype=nofile bufhidden=wipe
    execute "normal! ggdG" 
endfunction

function! s:CountRemainingWindows()
    let t:window_count = 0
    silent windo let t:window_count = t:window_count + 1
    return t:window_count
endfunction

function! s:WriteLine(line)
    execute "normal! I" .  a:line . "\<cr>"
endfunction

function! s:BufferReadOnly()
    setlocal nomodifiable readonly
endfunction

function! s:FindFolder(folder)
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

" }}}
