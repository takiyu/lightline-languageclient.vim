" ------------------------------------------------------------------------------
" --------------------------- Configurable Variables ---------------------------
" ------------------------------------------------------------------------------
let s:indicator_ok = get(g:, 'lightline#languageclient#indicator_ok', 'OK')
let s:indicator_ns = get(g:, 'lightline#languageclient#indicator_ns', 'N/S')
let s:indicator_e = get(g:, 'lightline#languageclient#indicator_e', 'E:%d')
let s:indicator_w = get(g:, 'lightline#languageclient#indicator_w', 'W:%d')
let s:indicator_i = get(g:, 'lightline#languageclient#indicator_i', 'I:%d')

" ------------------------------------------------------------------------------
" ------------------------------ Script Variables ------------------------------
" ------------------------------------------------------------------------------
let s:language_client_started = 0
let s:last_diag_exists = 0
let s:last_diag_list = []

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
    " Check error existence
    let l:diag_list = lightline#languageclient#_getDiagList()
    if len(l:diag_list) == 0
        return ''
    else
        return lightline#languageclient#_countUpErrors(l:diag_list)
    endif
endfunction

function! lightline#languageclient#ok() abort
    if !lightline#languageclient#_isServerAlive()
        return ''
    endif
    " Check error existence
    let l:diag_list = lightline#languageclient#_getDiagList()
    if !lightline#languageclient#_isLinted()
        return s:indicator_ns
    endif
    if len(l:diag_list) == 0
        return s:indicator_ok
    else
        return ''
    endif
endfunction

" ------------------------------------------------------------------------------
" ------------------------------- Implementation -------------------------------
" ------------------------------------------------------------------------------
function! lightline#languageclient#_isServerAlive()
    return (s:language_client_started == 1) &&
         \ (LanguageClient_serverStatus() == 0)
endfunction

function! lightline#languageclient#_isLinted()
    return (s:last_diag_exists == 1)
endfunction

function! lightline#languageclient#_getDiagList()
    return s:last_diag_list
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
        let l:result = lightline#languageclient#_parseJsonString(l:result_str)

        let full_filename = expand('%:p')
        let l:diagnostics = l:result.diagnostics
        if has_key(l:diagnostics, full_filename)
            " Return
            let s:last_diag_exists = 1
            let s:last_diag_list = l:diagnostics[full_filename]
        else
            let s:last_diag_exists = 0
            let s:last_diag_list = []
        endif
    catch
        echohl 'Something wrong in LanguageClient state parsing for lightline'
        let s:last_diag_exists = 0
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
    " Convert string to dictionary
    let l:json_dict = eval(l:json_str)
    return l:json_dict
endfunction
