if !has('nvim') || exists('git_vim_loaded')
  finish
endif

let git_vim_loaded = 1
let s:git_scratch_buffer = '__GitScratch__'

command! -nargs=1 GitPush !bash -c "git push origin HEAD:<args>"
command! GitAddAll silent !git add -A
command! GitBlame git#GitBlame()
command! GitBranchCurrent echom 'Current branch: ' . GetCurrentBranch()
command! GitBranchNew git#GitNewBranch()
command! GitCommit git#GitCommitTerminal()
command! GitDiff git#GitDiff('')
command! GitDiffCached git#GitDiff('--cached')
command! GitFetch silent terminal bash -c "git fetch"
command! GitHelp git#GitHelp()
command! GitLog git#GitLog()
command! GitFetchMaster git#GitFetchAndMergeOriginMaster()
command! GitPushCurrentBranch git#PushToCurrentBranch()
command! GetRefLog git#GitRefLog()
command! GitStatus git#GitStatus()
