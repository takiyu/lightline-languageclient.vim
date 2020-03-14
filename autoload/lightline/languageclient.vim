" ------------------------------------------------------------------------------
" --------------------------- Configurable Variables ---------------------------
" ------------------------------------------------------------------------------
let s:indicator_ok = get(g:, 'lightline#languageclient#indicator_ok', 'OK')
let s:indicator_ns = get(g:, 'lightline#languageclient#indicator_ns', 'N/S')
let s:indicator_fd = get(g:, 'lightline#languageclient#indicator_ns', 'Failed')
let s:indicator_e = get(g:, 'lightline#languageclient#indicator_e', 'E:%d')
let s:indicator_w = get(g:, 'lightline#languageclient#indicator_w', 'W:%d')
let s:indicator_i = get(g:, 'lightline#languageclient#indicator_i', 'I:%d')

" ------------------------------------------------------------------------------
" ------------------------------ Script Variables ------------------------------
" ------------------------------------------------------------------------------
let s:language_client_started = 0
let s:last_diag_state = 0
let s:last_diag_list = []
let s:last_state_result_json = ''  " For Debug
let s:last_state_result_raw = ''   " For Debug
let s:last_filename = ''     " For Debug

" ------------------------------------------------------------------------------
" -------------------------------- Entry Points --------------------------------
" ------------------------------------------------------------------------------
function! lightline#languageclient#onStarted() abort
    let s:language_client_started = 1
    call lightline#languageclient#update()
endfunction

function! lightline#languageclient#onStopped() abort
    let s:language_client_started = 0
    call lightline#languageclient#update()
endfunction

function! lightline#languageclient#onChanged() abort
    let s:language_client_started = 1
    call lightline#languageclient#update()
endfunction

function! lightline#languageclient#update() abort
    if lightline#languageclient#_isServerAlive()
        call lightline#languageclient#_updateDiagList()
    endif
endfunction

" ------------------------------------------------------------------------------
" ------------------------ Indicator String Generators -------------------------
" ------------------------------------------------------------------------------
function! lightline#languageclient#errors() abort
    if !lightline#languageclient#_isServerAlive()
        return ''
    endif
    " Failed indicator
    if lightline#languageclient#_isFailed()
        return s:indicator_fd
    endif
    " Diagnostics indicator
    if lightline#languageclient#_isLinted()
        " Check error existence
        let l:diag_list = lightline#languageclient#_getDiagList()
        if len(l:diag_list) != 0
            return lightline#languageclient#_countUpErrors(l:diag_list)
        endif
    endif
    return ''
endfunction

function! lightline#languageclient#ok() abort
    if !lightline#languageclient#_isServerAlive()
        return ''
    endif
    " Not-supported indicator
    if lightline#languageclient#_isNotSupported()
        return s:indicator_ns
    endif
    " Diagnostics indicator
    if lightline#languageclient#_isLinted()
        " Check error existence
        let l:diag_list = lightline#languageclient#_getDiagList()
        if len(l:diag_list) == 0
            return s:indicator_ok
        endif
    endif
    return ''
endfunction

" ------------------------------------------------------------------------------
" ------------------------------- Implementation -------------------------------
" ------------------------------------------------------------------------------
function! lightline#languageclient#_isServerAlive()
    return (s:language_client_started == 1) &&
         \ (LanguageClient_serverStatus() == 0)
endfunction

function! lightline#languageclient#_isLinted()
    return (s:last_diag_state == 1)
endfunction

function! lightline#languageclient#_isNotSupported()
    return (s:last_diag_state == 0)
endfunction

function! lightline#languageclient#_isFailed()
    return (s:last_diag_state == -1)
endfunction

function! lightline#languageclient#_getDiagList()
    return s:last_diag_list
endfunction

function! lightline#languageclient#_getStateResultRaw()
    return s:last_state_result_raw
endfunction

function! lightline#languageclient#_getStateResultJson()
    return s:last_state_result_json
endfunction

function! lightline#languageclient#_getFilename()
    return s:last_filename
endfunction

function! lightline#languageclient#_countUpErrors(diag_list) abort
    " Count up error and warn
    let l:n_err = 0
    let l:n_warn = 0
    let l:n_info = 0
    for item in a:diag_list
        if item["severity"] == 1
            let l:n_err += 1
        elseif item["severity"] == 2
            let l:n_warn += 1
        else
            let l:n_info += 1
        endif
    endfor
    " Create strings
    let l:items = []
    if 0 < l:n_err
        call add(l:items, printf(s:indicator_e, l:n_err))
    endif
    if 0 < l:n_warn
        call add(l:items, printf(s:indicator_w, l:n_warn))
    endif
    if 0 < l:n_info
        call add(l:items, printf(s:indicator_i, l:n_info))
    endif
    " Return message
    return join(l:items, ', ')
endfunction

function! lightline#languageclient#_updateDiagList() abort
    " Get diagnostics state by callback interface
    let l:callback_name = 'lightline#languageclient#_updateDiagListCallback'
    call LanguageClient#getState(function(l:callback_name))
endfunction

function! lightline#languageclient#_updateDiagListCallback(state)
    try
        " Restore result dictionary
        let l:result_str = a:state.result
        let s:last_state_result_raw = l:result_str  " Store for debug
        let l:result = lightline#languageclient#_parseJsonString(l:result_str)
        let s:last_state_result_json = l:result  " Store for debug

        " Look up with current filename
        let l:full_filename = expand('%:p')
        let s:last_filename = l:full_filename  " Store for debug
        let l:diagnostics = l:result.diagnostics
        if has_key(l:diagnostics, l:full_filename)
            " Return
            let s:last_diag_state = 1  " Success
            let s:last_diag_list = l:diagnostics[l:full_filename]
        else
            let s:last_diag_state = 0  " Not supported
            let s:last_diag_list = []
        endif
    catch
        echohl 'Something wrong in LanguageClient state parsing for lightline'
        let s:last_diag_state = -1  " Failed
        let s:last_diag_list = []
    endtry

    " Invoke the next event
    call lightline#update()
endfunction

function! lightline#languageclient#_parseJsonString(src_str) abort
    " Replace invalid values for VimScript
    let l:json_str = a:src_str
    let l:json_str = substitute(l:json_str, "true", "1", "g")
    let l:json_str = substitute(l:json_str, "false", "0", "g")
    let l:json_str = substitute(l:json_str, "null", "\"\"", "g")
    let l:json_str = substitute(l:json_str, "undefined", "\"\"", "g")
    let l:json_str = substitute(l:json_str, "\\n", " ", "g")
    " Convert string to dictionary
    let l:json_dict = eval(l:json_str)
    return l:json_dict
endfunction
