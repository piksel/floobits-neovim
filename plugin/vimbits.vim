" Copyright Floobits Inc 2013

if !has('python')
    echohl WarningMsg |
    \ echomsg "Sorry, the Floobits Vim plugin requires a Vim compiled with +python." |
    \ echohl None
    finish
endif

if exists("g:floobits_plugin_loaded")
    finish
endif

if !exists("floo_log_level")
    let floo_log_level = "msg"
endif
if !exists("floo_delete_local_files")
    let floo_delete_local_files = 1
endif
if !exists("floo_show_highlights")
    let floo_show_highlights = 1
endif
if !exists("floo_sparse_mode")
    let floo_sparse_mode = 0
endif

" p flag expands the absolute path. Sorry for the global
let g:floobits_plugin_dir = expand("<sfile>:p:h")

python << END_PYTHON
import os, sys
import vim
sys.path.append(vim.eval("g:floobits_plugin_dir"))

END_PYTHON

if filereadable(expand("<sfile>:p:h")."/floobits.py")
    pyfile <sfile>:p:h/floobits.py
else
    echohl WarningMsg |
    \ echomsg "Floobits plugin error: Can't find floobits.py in ".g:floobits_plugin_dir |
    \ echohl None
    finish
endif

function! s:MaybeChanged()
    if &modified
        python maybe_buffer_changed()
    endif
endfunction

function! g:FlooSetReadOnly()
    " this doesn't work for the first time from dired ?!?
    setlocal nomodifiable
endfunction

function! g:floobits_global_tick()
    python global_tick()
endfunction

function! s:SetAutoCmd()
    let s:vim_events = ['InsertEnter', 'InsertChange', 'InsertLeave', 'QuickFixCmdPost', 'FileChangedShellPost', 'CursorMoved', 'CursorMovedI']
    let s:new_buf_events = ['BufWritePost', 'BufReadPost', 'BufWinEnter']
    augroup floobits
        " kill autocommands on reload
        autocmd!
        for cmd in s:vim_events
            exec 'autocmd '. cmd .' * call s:MaybeChanged()'
        endfor

        autocmd CursorHold * python cursor_hold()
        autocmd CursorHoldI * python cursor_holdi()
        autocmd CursorMoved * python maybe_selection_changed()
        autocmd CursorMovedI * python maybe_selection_changed()
        for cmd in s:new_buf_events
            exec 'autocmd '. cmd .' * python maybe_new_file()'
        endfor

        autocmd BufEnter * python buf_enter()
        autocmd BufWritePost * python on_save()
        " milliseconds
        if has('async')
            call setinterval(100, 'g:floobits_global_tick')
        endif
    augroup END
endfunction

"TODO: populate with a default url of https://floobits.com/r/
command! -nargs=1 FlooJoinWorkspace :python join_workspace(<f-args>)
command! -nargs=1 FlooJoinworkspace :python join_workspace(<f-args>)

command! FlooLeaveWorkspace :python part_workspace()
command! FlooPartworkspace :python part_workspace()

command! FlooToggleFollowMode :python follow()

command! FlooSummon :python maybe_selection_changed(True)
command! FlooPing :python maybe_selection_changed(True)

command! FlooDeleteBuf :python delete_buf()

command! FlooPause :python floo_pause()
command! FlooUnPause :python floo_unpause()

command! -nargs=1 -complete=dir FlooShareDir :python share_dir(<f-args>)
command! -nargs=? -complete=file FlooAddBuf :python add_buf(<f-args>)

command! FlooInfo :python floo_info()

call s:SetAutoCmd()
let g:floobits_plugin_loaded = 1
