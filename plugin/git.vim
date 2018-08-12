if !has('nvim') || exists('git_vim_loaded')
  finish
endif

let git_vim_loaded = 1

command! -nargs=1 GitPush !bash -c "git push origin HEAD:<args>"
command! GitAddAll silent !git add -A
command! GitBlame call git#GitBlame()
command! GitBranchCurrent echom 'Current branch: ' . GetCurrentBranch()
command! GitBranchNew call git#GitNewBranch()
command! GitCommit call git#GitCommitTerminal()
command! GitDiff call git#GitDiff('')
command! GitDiffCached call git#GitDiff('--cached')
command! GitFetch silent terminal bash -c "git fetch"
command! GitHelp call git#GitHelp()
command! GitLog call git#GitLog()
command! GitFetchMaster call git#GitFetchAndMergeOriginMaster()
command! GitPushCurrentBranch call git#PushToCurrentBranch()
command! GetRefLog call git#GitRefLog()
command! GitStatus call git#GitStatus()
